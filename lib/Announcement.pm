# Announcement.pm: Handling of announced instances
#
# Copyright (C) 2012 GFZ Deutsches GeoForschungsZentrum Potsdam <lars.lindner@gfz-potsdam.de>
# Copyright (C) 2014 Lars Windolf <lars.windolf@gmx.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package Announcement;

use warnings;
use strict;
use DB;
use Notification;
use Settings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	announcement_add
	announcement_clear
	announcement_set_timeout
	announcements_fetch
);

################################################################################
# Helper method to build unique announcement keys.
#
# $1	announcement type ('component' or 'interface')
# $2	the event producing the announcement
#
# Returns the announcement key
################################################################################
sub build_announcement_key {
	my ($type, $event) = @_;

	unless(defined($event->{'host'}) and
	       defined($event->{'component'}) and
	       defined($event->{'ctxt'})) {
		print STDERR "ERROR: Announcement event without host/component/ctxt!\n";
		print STDERR Data::Dumper->Dump([$event], ['event']);
		return;
	}
	if($type eq "interface") {
		unless(defined($event->{'newcomponent'}) and
		       defined($event->{'newctxt'})) {
			print STDERR "ERROR: Interface announcement event without newcomponent/newctxt!\n";
			print STDERR Data::Dumper->Dump([$event], ['event']);
			return;
		}
	}

	my $akey = "announce!$type!$event->{host}!$event->{component}!";

	$akey .= "$event->{ctxt}" if($type eq "component");
	$akey .= "$event->{ctxt}!$event->{newcomponent}!$event->{newctxt}" if($type eq "interface");

	return $akey;
} 

################################################################################
# Add new announcement with a given TTL
#
# $1	announcement type ('component' or 'interface')
# $2	the event producing the announcement
# $3	TTL [s]
################################################################################
sub announcement_add {
	my ($type, $event, $ttl) = @_;

	my $akey = build_announcement_key($type, $event);

	# Do not readd/reset existing announcements
	return if(DB->exists($akey) == 1);

	DB->hset($akey, 'host',			$event->{'host'});
	DB->hset($akey, 'component',		$event->{'component'});
	DB->hset($akey, 'ctxt',			$event->{'ctxt'});
	DB->hset($akey, 'type',			$event->{'type'});

	if(defined($event->{'newctxt'})) {
		DB->hset($akey, 'newcomponent',		$event->{'newcomponent'});
		DB->hset($akey, 'newctxt',		$event->{'newctxt'});
	}

	DB->hset($akey, 'time',			time());
	DB->hset($akey, 'status',		'announced');
	DB->hset($akey, 'source',		notification_build_key($event));
	# FIXME: TTL should be timeout + some buffer (maybe x10) as global
	# TTL might be near endless for archiving
	DB->expire($akey, $ttl);
}

################################################################################
# Clear existing announcement
#
# $1	announcement type ('component' or 'interface')
# $2	the announcement event to be cleared
#
# Returns the deleted announcement event (or undef)
################################################################################
sub announcement_clear {
	my ($type, $event) = @_;

	# Handling components is simple...
	if($type eq 'component') {
		my $akey = build_announcement_key($type, $event);
		# Brute force rebuild announcement to ensure we have one
		announcement_add($type, $event, 30);	# FIXME: get rid of hard-coded TTL
		# And mark it as done
		DB->hset($akey, 'status', 'finished');
		return;
	}

	# And for interfaces...

	# We cannot use build_announcement_key() here as we have not all
	# necessary values (source host/source component...). So we need
	# to delete based on match pattern
	foreach(DB->keys("announce!$type!*!$event->{component}!$event->{ctxt}")) {
		my $akey = $_;
		my %announcement = DB->hgetall($akey);
		if($announcement{'type'} eq 'c') {
			# Set announcement status in announcement AND event 
			# data. The info in the event data is considered the
			# long term info as the announcement info has much 
			# shorter life cycle.
			DB->hset($akey, 'status', 'finished');
			DB->hset($announcement{'source'}, 'status', 'finished');
		}
		return \%announcement;
	}

	return undef;
}

################################################################################
# Mark the given announcement as run into a timeout
#
# $1	announcement type ('component' or 'interface')
# $2	the announcement event to time-out
################################################################################
sub announcement_set_timeout {

	DB->hset(build_announcement_key(shift, @_), 'status', 'timeout');
}

################################################################################
# Generic announcement fetching method. Provides filtering as fetch() does.
#
# $1	announcement type ('component' or 'interface')
# $2	Hash reference with Redis glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
#	Example: Get all announced DB sync jobs
#
#		("ctxt" => "sync?", "component" => "db")
#
# Returns an array of result hashes	(undefined on error)
################################################################################
sub announcements_fetch {
	my ($type, $glob) = @_;

	# Build fetching glob
	my $filter = "announce!$type!";
	$filter .= "$glob->{host}!*"		if(defined($glob->{'host'}));
	# FIXME: Missing *
	$filter .= "$glob->{component}!*"	if(defined($glob->{'component'}));
	$filter .= "$glob->{ctxt}!*"		if(defined($glob->{'ctxt'}));
	$filter .= "*"				unless($filter =~ /\*$/);

	# Deserialize query results into a list of events grouped
	# for spur (a host, component, context) sets.
	my @results = ();
	my $i = 0;
	foreach my $key (DB->keys($filter)) {
		next if($key =~ /skipped because its mtime/);
		my %event = DB->hgetall($key);
		push(@results, \%event);

		last if($i++ > 100);	# FIXME: hard coded!
	}

	return \@results;
}

1;
