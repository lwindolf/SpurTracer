# Spuren.pm: SpurTracer Spuren Data Access
# FIXME: Rename to "Events.pm"
#
# Copyright (C) 2011 Lars Lindner <lars.lindner@gmail.com>
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


package Spuren;

use strict;
use warnings;
use locale;
use POSIX qw(strftime);
use Error qw(:try);

use Announcement;
use DB;
use Notification;
use Spur;
use Stats;
use Settings;

my $debug = 0;

################################################################################
# Constructor
################################################################################
sub new {
	my $type = shift;
	my $this = { };
	my $settings = settings_get("spuren", "global");

	$this->{'stats'} = new Stats();
	$this->{'ttl'} = $settings->{'ttl'};
	warn "No TTL defined!" unless(defined($this->{'ttl'}));

	return bless $this, $type;
}

################################################################################
# Add submitted data
#
# $2	hash with notification properties 
#	("host" => "host1", "component" => "db", ...)
#
# Returns 0 on success
################################################################################
sub add_event {
	my ($this, %data) = @_;

	if($debug) {
		print STDERR "New notification:\n";
		foreach(keys(%data)) {
			print STDERR "	$_ => $data{$_}\n";
		}
	}

	# Sanity check date before processing, we expect a [ms] Unix timestamp,
	# but accept a normal timestamp too... FIXME: Better way to check this?
	$data{'time'} *= 1000 if($data{'time'} < 1000000000000);

	# Before adding the notification determine the status for announcements
	# by checking for relevant existing notifications...
	if($data{'type'} eq "c") {
		my @notifications = DB->keys(notification_build_filter(
			'component'	=> $data{'newcomponent'},
			'ctxt'		=> $data{'newctxt'}
		));
		if($#notifications < 0) {
			$data{'status'} = 'announced';
		} else {
			$data{'status'} = 'finished';
		}
	}

	notification_add(\%data, $this->{'ttl'});

	if($data{'type'} eq "c") {
		# For context announcements:

		# Interface Announcement Handling
		unless($data{'status'} eq 'finished') {
			announcement_add('interface', \%data, $this->{'ttl'});
			$this->{'stats'}->add_interface_announced($data{host}, $data{component}, $data{newcomponent});
		} else {
			print STDERR "Not adding announcement as interface was already triggered!\n" if($debug);
		}
	} else {
		if($data{'status'} eq "started") {
			$this->{'stats'}->add_start_notification($data{'host'}, $data{'component'});

			# Interface Performance Data Handling
			my $announcement = announcement_clear('interface', \%data);
			$this->{'stats'}->add_interface_duration($announcement->{'host'}, $announcement->{'component'}, $data{'component'}, ($data{'time'} - $announcement->{'time'})) if(defined($announcement));

			# Announce Component

			# FIXME: DO we need a race check here too?
			announcement_add('component', \%data, $this->{'ttl'});
			$this->{'stats'}->add_component_announced($data{host}, $data{component});
		}

		if($data{'status'} eq "finished") {
			# Component Performance Data Handling
			my $announcement = announcement_clear('component', \%data);
			$this->{'stats'}->add_component_duration($data{'host'}, $data{'component'}, $data{'time'}, $announcement);

			# Do count spur chain type. This is simply to collect all 
			# existing types. To determine the chain we backtrack the
			# announcements...
			spur_add(\%data);
		}

		if($data{'status'} eq "failed") {
			$this->{'stats'}->add_error_notification($data{'host'}, $data{'component'});
		}
	}

	return 0;
}

################################################################################
# Add a new timeout event
#
# $2	'component' or 'interface'
# $3	reference to the event hash
################################################################################
sub add_timeout {
	my ($this, $type, $announcement) = @_;

	announcement_set_timeout($type, $announcement);

	my %event = %$announcement;
	$event{'status'} = 'timeout';
	$event{'type'} = 'n';
	$event{'time'} = time()*1000;

	if($type eq 'interface') {
		$event{'desc'} = ucfirst($type)." timeout for $announcement->{newcomponent} (context $announcement->{newctxt}) detected by SpurTracer";

		$this->{'stats'}->add_interface_timeout($announcement->{'host'},
			                                $announcement->{'component'},
			                                $announcement->{'newcomponent'});
	} elsif($type eq 'component') {
		$this->{'stats'}->add_component_timeout($announcement->{'host'},
		                                        $announcement->{'component'});
	}

	notification_add(\%event, $this->{'ttl'});

	if($type eq 'interface') {
		# Do count spur chain type as we will never get a 
		# 'finished' event which would add the spur if a timeout
		# happens and we might never know about the spur 
		spur_add(\%event);
	}
}

################################################################################
# Generic fetching method providing filtering. We heavily rely on Redis
# key matching and hope for it to be performing well... The Redis documentation
# warns to not use the KEYS method for production, so this might not work
# on the long term.
#
# $2	List with filter rules as supported by notification_build_regex()
#
#	Example: Get all CMS notification for all appservers
#
#		("host" => "appserver?", "component" => "cms")
#
# Returns an array of result hashes
################################################################################
sub fetch {
	my ($this, %glob) = @_;

	my @keys = @{notifications_fetch(notification_build_regex(%glob), 1000)};

	# Deserialize query results into a list of events
	# for (host, component, context) sets. The results will
	# be a list of such sets...
	my %results;
	foreach my $key (@keys) {
		my $event = notification_get($key);
		if(defined($event)) {
			my $id = $event->{'host'}."!".$event->{'component'}."!".$event->{'ctxt'};

			unless(defined($results{$id})) {
				next if(keys %results > 100);
				$results{$id}{'source'}{'host'}		= $event->{'host'};
				$results{$id}{'source'}{'component'}	= $event->{'component'};
				$results{$id}{'source'}{'ctxt'}		= $event->{'ctxt'};
				$results{$id}{'source'}{'started'}	= $event->{'time'};	# ensure we have some time if 'started' event is missing
				$results{$id}{'events'} = ();
			}

			if(defined($event->{'status'}) and $event->{'status'} eq 'started') {
				$results{$id}{'source'}{'started'} = $event->{'time'}
			}

			# Add event to spur set
			push(@{$results{$id}{'events'}}, $event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n" if($debug);
		}
	}

	return \%results;
}

1;

__END__

=head1 Spuren - Data Access and Model

Spuren is the data access for single notification events or groups of
events matching a filter or all related events. As we consider relations
interface invocations to be regular we also want to provide access to
the typical interface patterns. Therefore our schema must allow 
tracking those.

=head2 Access Variants

One or more spur events can be accessed

1.) per object filter (e.g. all for "host1")
2.) per identity (e.g. all requests for context id 123456)

Tracking of spur types (interface chains) additionally requires the ability
to backtrack events based on the last context id.

Both access variants (filter and backtracking) are realised using the 
key schema implemented in Notification.pm. As the keys are used for lookup
only the data structure is implemented in "Spuren" as described in the
next section

=head2 Event Properties

=begin text

We trace behaviour by correlating all notifications with the following 
general properties:

- host	 				...the hosts name the notification 
					originates from (not necessarily
					fully qualified)
- component 				...producing the notification
- ctxt					Context Identifier
- time					Unix Time Stamp in [ms]
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

NOTE: DON'T RELY ON THE SCHEMA IT MIGHT CHANGE AT ANY TIME!

=end text

=cut
