# Spur.pm: Handling a single spur (interface chain)
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

package Spur;

use warnings;
use strict;
use Notification;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
		spur_build_key
		spur_add
		spur_fetch
);

################################################################################
# Build a Redis key for the "spuren" namespace. For now we consider an edge
# graph encoded as following as a unique spur id schema:
#
#	<component>_<component>[!<component>_<component>[...]]
#
# $1	spur array reference
#
# Returns a new key string
################################################################################
sub spur_build_key {
	my $events = shift;
	my $key = "";

	foreach my $event (@$events) {
		$key .= "!" unless($key eq "");
		$key .= "$event->{component}_$event->{newcomponent}";
	}

	return "spuren!$key";
}

################################################################################
# Resolve and add a spur. Takes an event description and tries to find all
# predecessor announcement events. Relies only on the 'newcomponent' and
# 'newctxt' event fields.
#
# Adds the resulting spur to Redis
#
# $1	event hash reference
################################################################################
sub spur_add {
	my $event = shift;	# event to resolve
	my @results = ();
	my %tmp = ();		# lookup hash for cycle detection 

	# Note: We do not need to find call tree branches, just the direct 
	# ancestor, as each call tree branch end-component's 'finished' event
	# will trigger spur_add()
	#
	# For example: The following component call tree
	#
	#    C1 ----> C2 ----> C3
	#     \-----> C4 ----> C5
	#              \-----> C6
	#
	# would cause 3 spur types to be saved:
	#
	#    C1-C2-C3
	#    C1-C4-C5
	#    C1-C4-C6
	
	EVENTLOOP: while(defined($event)) {

		my $filter = notification_build_filter((
			'newcomponent'	=> $event->{'component'},
			'newctxt'	=> $event->{'ctxt'}
		));

		$event = undef;

		# Match any event announcing the component+ctxt of this event
		foreach my $key (DB->keys($filter)) {
			# Cycle detection
			last EVENTLOOP if(defined($tmp{$key}));
			$tmp{$key} = 1;

			$event = notification_get($key);
			unshift(@results, $event);
			last;
		}
	}

	if($#results >= 0) {
		my $key = spur_build_key(\@results);
		DB->hincrby($key, 'finished', 1);
	}
}

################################################################################
# Fetch all spur keys matching the optional filter.
#
# $1	reference to an array of all known matching spur types
#
# Returns an array reference with the resulting spur types
################################################################################
sub spur_fetch {
	# FIXME: Implement filter
	my $filter = "*";
	my %results;

	my @tmp;
	my $i = 0;
	# Sort by string as equally long unique paths
	# cannot contain each other and reverse sort ensures
	# longest paths are processed first. Matching against
	# already processed paths in @tmp eliminates partial
	# spur types.
	SPURLOOP: foreach(reverse sort DB->keys("spuren!$filter")) {
		next unless(/^spuren!(.*)$/);
		my $spur = $1;

		# Eliminate partial spur types
		#
		# E.g. C1->C2 is part of C1->C2->C3
		foreach(@tmp) {
			next SPURLOOP if(index($_, $spur) != -1);
		}
		push(@tmp, $spur);

		my @spur = ();
		foreach(split(/!/, $spur)) {
			if(/^(\w+)_(\w+)$/) {
				push(@spur, { 'from' => $1, 'to' => $2 });
			}
		}
		$results{$i++} = \@spur;
	}

	return \%results;
}

1;
