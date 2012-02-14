# Announcement.pm: Handling of announced events
#
# Copyright (C) 2012 Lars Lindner <lars.lindner@gmail.com>
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

use DB;
use Settings;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	announcement_add
	announcement_clear
	announcement_set_timeout
	announcements_fetch
);

################################################################################
# Helper method to build announcement keys
#
# $1	announcement type ('component' or 'interface')
# $2	the event producing the announcement
#
# Returns the announcement key
################################################################################
sub build_announcement_key {
	my ($type, $event) = @_;
	my $akey = "announce!$type!";

	if($event->{'type'} eq 'c') {
		# 1. Announcements
		#
		# 1.a) Component announcements are implicitely triggered on 
		#      'started' events so the component name is the name 
		#      of the announced component
		$akey .= "$event->{component}!$event->{ctxt}" if($type eq "component");
		#
		# 1.b) Interface announcement are caused by context announcement
		#      events which provide the names of the new component/ctxt
		$akey .= "$event->{newcomponent}!$event->{newctxt}" if($type eq "interface");
	} else {
		# 2. Clear/Timeout Announcement
		#
		# Component clears/timeouts are caused by the AlarmMonitor that
		# processes all existing notifications. The event structure 
		# contains the announcement event itself.
		$akey .= "$event->{component}!$event->{ctxt}";
	}

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
	DB->hset($akey, 'sourceHost',		$event->{'host'});
	DB->hset($akey, 'sourceComponent',	$event->{'component'});
	DB->hset($akey, 'sourceCtxt',		$event->{'ctxt'});
	DB->hset($akey, 'time',			time());
	DB->hset($akey, 'timeout',		0);
	DB->expire($akey, $ttl);
}

################################################################################
# Clear existing announcement
#
# $1	announcement type ('component' or 'interface')
# $2	the announcement event to be cleared
################################################################################
sub announcement_clear {

	DB->del(build_announcement_key(@_));
}

################################################################################
# Mark the given timeout as run into a timeout
#
# $1	announcement type ('component' or 'interface')
# $2	the announcement event to time-out
################################################################################
sub announcement_set_timeout {

	DB->hset(build_announcement_key(@_), 'timeout', 1);
}

################################################################################
# Generic announcement fetching method. Provides filtering as fetch() does.
#
# $1	announcement type ('component' or 'interface')
# $2	Hash with Redis glob patterns. Can be empty to fetch the
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
	my ($type, %glob) = @_;

	# Build fetching glob
	my $filter = "announce!$type!";
	$filter .= "$glob{component}!*"	if(defined($glob{'component'}));
	$filter .= "$glob{ctxt}!*"	if(defined($glob{'ctxt'}));
	$filter .= "*"			unless($filter =~ /\*$/);

	# Deserialize query results into a list of events grouped
	# for spur (a host, component, context) sets.
	my @results = ();
	my $i = 0;
	foreach my $key (DB->keys($filter)) {
		next if($key =~ /skipped because its mtime/);

		# Decode value store key according to schema 
		#
		# announce!component!<component>
		# announce!interface!<component>!<ctxt>
		if($key =~ /announce!$type!([^!]+)!([^!]+)$/) {
			$i++;

			# Add event to set
			my %event = DB->hgetall($key);
			$event{'component'} = $1;
			$event{'ctxt'} = $2;

			push(@results, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}

		last if($i > 100);
	}

	return \@results;
}

1;
