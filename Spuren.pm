# Spuren.pm: SpurTracer Spuren Data Access
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


package Spuren;

use locale;
use POSIX qw(strftime);
use Error qw(:try);

use Announcement;
use DB;
use Notification;
use Stats;
use Settings;

$debug = 0;

################################################################################
# Constructor
################################################################################
sub new {
	my $type = shift;
	my $this = { };
	my $settings = settings_get("spuren", "global");

	$this->{'stats'} = new Stats();
	$this->{'today'} = strftime("%F", localtime());
	$this->{'ttl'} = $settings->{'ttl'};
	die "Not TTL!" unless(defined($this->{'ttl'}));

	return bless $this, $type;
}

################################################################################
# Time formatting helper
#
# $1	Unix time stamp
#
# Returns string with formatted date
################################################################################
sub nice_time {
	my ($this, $ts) = @_;

	my $result = strftime("%F %T", localtime($ts));
	$result =~ s/^$this->{today} //;	# shorten time if possible

	return $result;
}

################################################################################
# Add submitted data
#
# $2	hash with notification properties 
#	("host" => "host1", "component" => "db", ...)
#
# Returns 0 on success
################################################################################
sub add_data {
	my ($this, %data) = @_;

	if($debug) {
		print STDERR "New notification:\n";
		foreach(keys(%data)) {
			print STDERR "	$_ => $data{$_}\n";
		}
	}

	my $key = notification_build_key(\%data);
	my $value = notification_build_value(\%data);

	# Submit value
	DB->set($key, $value);
	DB->expire($key, $this->{'ttl'});

	# Performance Data Handling
	$this->{'stats'}->add_component_duration($data{'host'}, $data{'component'}) if($data{'status'} eq 'finished');

	# Interface Announcement Handling
	if($data{'type'} eq "c") {
		# For context announcements:

		# Check if any notifications already exist, to avoid
		# adding announcements on races...
		my @notifications = $this->_query_redis((
			'component'	=> $data{newcomponent},
			'ctxt'		=> $data{newctxt}
		));

		if($#notifications < 0) {
			announcement_add('interface', \%data, $this->{'ttl'});
			$this->{'stats'}->add_interface_announced($data{host}, $data{component}, $data{newcomponent});
		} else {
			print STDERR "Not adding announcement as interface was already triggered!\n" if($debug);
		}
	} else {
		# For normal notifications: Always clear any existing announcement
		announcement_clear('interface', \%data);

		# Component Timeout Handling
		announcement_add('component', \%data, $this->{'ttl'})	if($data{'status'} eq "started");
		announcement_clear('component', \%data)			if($data{'status'} eq "finished");
	}

	# And finally the statistics
	$this->{'stats'}->add_start_notification($data{host}, $data{component}) if($data{status} eq "started");
	$this->{'stats'}->add_error_notification($data{host}, $data{component}) if($data{status} eq "failed");

	return 0;
}

################################################################################
# Run a query agains Redis.
#
# $2	List with filter rules as supported by notification_build_filter()
#
# Returns array of result hashes	(undefined on error)
################################################################################
sub _query_redis {
	my ($this, %glob) = @_;

	my $filter = notification_build_filter(%glob);
	#print STDERR "Querying for >>>$filter<<<\n" if($debug);

	return DB->keys($filter);
}

################################################################################
# Generic fetching method providing filtering. We heavily rely on Redis
# key matching and hope for it to be performing well... The Redis documentation
# warns to not use the KEYS method for production, so this might not work
# on the long term.
#
# Supported patterns see: http://redis.io/commands/keys
#
# $2	List with filter rules as supported by notification_build_filter()
#
#	Example: Get all CMS notification for all appservers
#
#		("host" => "appserver?", "component" => "cms")
#
# Returns an array of result hashes	(undefined on error)
################################################################################
sub fetch {
	my ($this, %glob) = @_;
	my @keys = $this->_query_redis(%glob);

	# Deserialize query results into a list of events
	# for (host, component, context) sets. The results will
	# be a list of such sets...
	my %results;
	my $i = 0;
	foreach my $key (@keys) {
		next if($key =~ /skipped because its mtime/);

		# Decode value store key according to schema 
		#
		# d<time>!h<host>!n<component>!c<ctxt>!t<type>![s<status>]
		if($key =~ /d(\d+)!h([^!]+)!n([^!]+)!c([^!]+)!t([nc])!(s(\w+))?/) {
			my $time = $1;
			my $id = $2."!".$3."!".$4;
			my $type = $5;
			my $status = $7;

			unless(defined($results{$id})) {
				next if(keys %results > 100);
				$results{$id}{source}{host} = $2;
				$results{$id}{source}{component} = $3;
				$results{$id}{source}{ctxt} = $4;
				$results{$id}{source}{started} = $time;
				$results{$id}{source}{startDate} = $this->nice_time($time);
				$results{$id}{events} = ();
				$i++;
			}

			my %event = ();
			$event{type} = $type;
			$event{time} = $time;
			$event{date} = $this->nice_time($time);
			$event{status} = $status if(defined($status));
			if($type eq "n") {
				$event{desc} = DB->get($key);
			} else {
				if(DB->get($key) =~ /^([^!]+)!([^!]+)$/) {
					$event{'newctxt'} = $2;
					$event{'newcomponent'} = $1;
					$event{status} = "announced";
					$event{status} = "finished" unless(DB->exists("announce!n$event{newcomponent}!c$event{newctxt}"));
				}
			}

			# Add event to spur set
			push(@{$results{$id}{events}}, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n" if($debug);
		}

		last if($i > 10000);
	}

	return \%results;
}

1;

__END__

=head1 Spuren - Data Access and Model

=head2 Notification Properties

=begin text

We trace behaviour by correlating even notifications with the following 
general properties:

- host	 				...the hosts name the notification 
					originates from (not necessarily
					fully qualified)
- component 				...producing the notification
- ctxt					Context Identifier
- time					Unix Time Stamp
- desc					Human readable description (optional)
- type 					notification/context creation

Each notification has the following type specific properties:

  For type "notification"

     - status 				running/start/finished/failed

  For type "context creation"

     - newctxt				New expected context identifier
			 		used to correlate two different 
					notification series

     - newcomponent			New expected component identifier
					used to correlate two different
					notification series

=end text

=head2 Redis Schema

=begin text

We layout the about notification properties in Redis as following

	Key Schema: 

		d<time>!h<host>!n<component>!c<ctxt>!t<type>![s<status>]

	Value Schema:

		For type 'notification'

			<description>

		For type 'context creation'

			<newctxt>

The assumption is that filtering is only necessary by for the properties
listed in the key schema. Prefixing each field with a character should
allow fast matching e.g. /!ndb!/ to find all notifications for the 
"db" component.

NOTE: DON'T RELY ON THE SCHEMA IT MIGHT CHANGE AT ANY TIME!

=end text

=cut
