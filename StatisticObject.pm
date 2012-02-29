# StatisticObject.pm: Handling of SpurTracer Statistic Objects
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

package StatisticObject;

use warnings;
use strict;
use POSIX;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	statistic_object_get
);

################################################################################
# Query method for performance values. Returns an hash of all value slots.
# Minimizes the resolution of the selected interval to $4 values.
#
# $1	Key 			(e.g. "object!component!comp2")
# $2	Interval Description
# $3	Resolution		(e.g. 100)
#
# Returns a result hash
################################################################################
sub statistic_object_get_performance {
}

################################################################################
# Generic interval counter query method. Returns an hash of all value slots.
# Minimizes the resolution of the selected interval to $4 values.
#
# $1	Key 			(e.g. "object!component!comp2")
# $2	Interval Description
# $3	Resolution		(e.g. 100)
# $*	List of counters 	(e.g. ("started", "failed"))
#
# Returns a result hash
################################################################################
sub statistic_object_get_counters {
	my $key = shift;
	my $interval = shift;
	my $resolution = shift;
	my @counters = @_;
	my %results;

	# Determine how many data points we have to aggregate for each step
	my $ratio = int($interval->{'resolution'} / $resolution);
	$ratio = 1 if($ratio < 1);

	# Skip unused 0 element at (n+1) used for ring buffer semantic from 
	# result by starting at (n+2) and wrapping around correctly...
	my $n = (time() / $interval->{'step'}) % ($interval->{'resolution'} + 1);

	foreach my $counter (@counters) {
		my %tmp = DB->hgetall("stats$interval->{name}!$key!$counter");
		# FIXME: Skip counters without values

		my $aggregatedValue = 0;
		my $i;
		my $j = 0;
		for($i = 0; $i < $interval->{'resolution'}; $i++) {

			# Some preconditions for interval extraction
			#
			# - We expect %tmp to be sorted
			# - We output starting at correct ring buffer offset n
			# - Undefined keys mean zero
			my $value = $tmp{(($n + 2 + $i) % ($interval->{'resolution'} + 1))};

			# Perform aggregation according to $ratio
			$aggregatedValue += $value if(defined($value));

			if($j++ == ($ratio - 1)) {			
				# Store aggregated average result
				$results{$counter}{int($i / $ratio)} = ceil($aggregatedValue / $ratio);
				$aggregatedValue = 0;
				$j = 0;
			}
		}
	}

	return \%results;
}

################################################################################
# Fetch a specific statistics object for one or more intervals
#
# $1	descriptive name of the statistics object (optional, can be undef)
# $1	'object' or 'instance'
# $2	statistics object key
# $3	array of interval definitions
#
# Returns a result array reference
################################################################################
sub statistic_object_get {
	my $name = shift;
	my $type = shift;
	my $key = shift;
	my @intervals = @_;
	my @results = ();

	$name = $key unless(defined($name));

	foreach my $interval (@intervals) {
		my %objStat = ();
		$objStat{'name'} = $name;
		$objStat{'performance'} = statistic_object_get_performance("$type!$key", $interval, 100);
		$objStat{'counters'} = statistic_object_get_counters("$type!$key", $interval, 100, ("started", "failed", "announced", "timeout"));
		$objStat{'interval'} = $interval->{'name'};
		push(@results, \%objStat);
	}

	return \@results;
}

1;
