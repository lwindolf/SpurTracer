# Notification.pm: Serialization / Parsing / Filtering helpers for notifications
#
# Copyright (C) 2012 GFZ Deutsches GeoForschungsZentrum Potsdam <lars.lindner@gfz-potsdam.de>
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

package Notification;

use warnings;
use strict;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
		notification_build_filter
		notification_build_regex
		notification_build_key
		notification_build_value
		notification_set_status
		notification_add
		notification_get
		notifications_fetch
);

################################################################################
# Build a Redis glob expression for searching notifications. To be used
# directly with the Redis "keys" method.
#
# $1	Hash with Redis glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
# Returns a glob pattern
################################################################################
sub notification_build_filter {
	my (%glob) = @_;

	# Build fetching glob
	my $filter = "";
	$filter .= "event!d$glob{time}!*"	if(defined($glob{'time'}));

	$filter = "event!d*!" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "h$glob{host}!*"		if(defined($glob{'host'}));
	$filter .= "n$glob{component}!*"	if(defined($glob{'component'}));
	$filter .= "c$glob{ctxt}!*"		if(defined($glob{'ctxt'}));
	$filter .= "t$glob{type}!*"		if(defined($glob{'type'}));

	# For type=n
	$filter .= "s$glob{status}"		if(defined($glob{'status'}));

	# For type=c
	$filter .= "N$glob{newcomponent}!C$glob{newctxt}" if(defined($glob{'newcomponent'}));

	$filter .= "*"	unless(defined($glob{'status'}) or defined($glob{'newctxt'}));

	return $filter;
}

################################################################################
# Build a Redis glob expression for searching notifications. To be used
# with notification_fetch()
#
# $1	Hash with glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
# Returns a glob pattern
################################################################################
sub notification_build_regex {
	my (%glob) = @_;

	# Build fetching glob
	my $filter = "";
	$filter .= "event!d$glob{time}!.*"	if(defined($glob{'time'}));

	$filter = "event!.*!" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "h$glob{host}!.*"		if(defined($glob{'host'}));
	$filter .= "n$glob{component}!.*"	if(defined($glob{'component'}));
	$filter .= "c$glob{ctxt}!.*"		if(defined($glob{'ctxt'}));
	$filter .= "t$glob{type}!.*"		if(defined($glob{'type'}));

	# For type=n
	$filter .= "s$glob{status}"		if(defined($glob{'status'}));

	# For type=c
	$filter .= "N$glob{newcomponent}!C$glob{newctxt}" if(defined($glob{'newcomponent'}));

	$filter .= ".*"	unless(defined($glob{'status'}) or defined($glob{'newctxt'}));

	return $filter;
}

################################################################################
# Build a notification key from a hash containing the notification properties
#
# $1	Event hash
#
# Returns a key string
################################################################################
sub notification_build_key {
	my %data = %{$_[0]};

	# Create value store key according to schema 
	#
	# event!d<time>!h<host>!n<component>!c<ctxt>!tn!s<status>
	# event!d<time>!h<host>!n<component>!c<ctxt>!tc!N<new component>!C<new ctxt>
	my $key = "event!";
	$key .= "d$data{time}!";
	$key .= "h$data{host}!";
	$key .= "n$data{component}!";
	$key .= "c$data{ctxt}!";
	$key .= "t$data{type}!";

	# For type=n
	$key .= "s$data{status}"	if(defined($data{'status'}));

	# For type=c
	$key .= "!N$data{newcomponent}"	if(defined($data{'newcomponent'}));
	$key .= "!C$data{newctxt}"	if(defined($data{'newctxt'}));

	return $key;
}

################################################################################
# Build a notification value from a has containing the notification properties
#
# $1	Event hash
#
# Returns a value string
################################################################################
sub notification_build_value {
	my %data = %{$_[0]};

	# Create value depending on type
	my $value = "";
	if($data{'type'} eq "n") {
		$value = $data{'desc'} if(defined($data{'desc'}));
	} else {
		$value = "$data{'newcomponent'}!$data{newctxt}";
	}

	return $value;
}

################################################################################
# Add a new notification to Redis
#
# $1	event hash reference
# $2	TTL
################################################################################
sub notification_add {
	my ($event, $ttl) = @_;

	my $key = notification_build_key($event);

	# Add a hash for random access
	foreach(keys(%$event)) {
		DB->hset($key, $_, $event->{$_});
	}
	DB->expire($key, $ttl);

	# Add each key to time sorted event index
	# (Note: no Redis TTL possible here, cleanup done in AlarmMonitor)
	DB->zadd('events', "$event->{time}", $key);
}

################################################################################
# Build event hash from Redis event key
#
# $1	Event key
#
# Returns a hash reference to the event (or undef)
################################################################################
sub notification_get {
	my $key = shift;
	my %event;

	# Validate key schema...
	#
	# event!d<time>!h<host>!n<component>!c<ctxt>!t<type>![s<status>]
	if($key =~ /event
			!d(?<time>\d+)
			!h(?<host>[^!]+)
			!n(?<component>[^!]+)
			!c(?<ctxt>[^!]+)
			!t(?<type>[nc])
			!(s(?<status>\w+))?
	           /x
	) {
		%event = DB->hgetall($key);
	}

	return \%event;
}

################################################################################
# Fetch notification keys according to optional filter
#
# $1	regex for key filtering
# $2	maximum number of keys to return
#
# Returns a array reference to the resulting keys
################################################################################
sub notifications_fetch {
	my $filter = shift;
	my $max = shift;
	my @keys = ();

	# FIXME loop if filtering reduces results belov $max
	foreach my $key (DB->zrevrangebyscore('events', '+inf', '-inf', 'limit', 0, $max)) {
		next if($key =~ /skipped because its mtime/);
		push(@keys, $key) if($key =~ /$filter/);
	}

	return \@keys;
}

1;

__END__

=head1 Notification - Data Access Key Schema

The notification key schema is to allow filtering and spur type (interface
chain) backtracking.

To support filtering it needs to expose all necessary information for full text 
matching without loosing type information (e.g. we want to match a host name not 
a component name). This is realized by a prefix character in each namespace
schema field.

To support spur type backtracking we need the full interface invocation relation
(new component, new context) for all announcement notifications (type=c).

=head2 Redis Key Schema

=begin text

We layout the notification properties in Redis as following

	Key Schema for Notifications:

		event!d<time>!h<host>!n<component>!c<ctxt>!tn!s<status>

	Key Schema for Context Announcements: 

		event!d<time>!h<host>!n<component>!c<ctxt>!tc!N<new component>!C<new ctxt>


The assumption is that filtering is only necessary by for the properties
listed in the key schema. Prefixing each field with a character should
allow fast matching e.g. /!ndb!/ to find all notifications for the 
"db" component.

NOTE: DON'T RELY ON THE SCHEMA IT MIGHT CHANGE AT ANY TIME!

=end text

=head2 Accessing Notification Properties

=begin text

Notification properties are to be accessed using random access by 
fetching the hash from the "event" namespace. This is implemented by
notification_get()

=end text

=head2 Fetching Notification Lists

=begin text

To fetch sets of notifications we perform a range query on the ZSET "events".
This is implemented in notifications_fetch(). The ordered list is ordered
by [ms] Unix timestamps and provides only the notification key names. The
key name has to be looked up in the "event" namespace as described in the
previous section.

=end text
