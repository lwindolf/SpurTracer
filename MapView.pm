# MapView.pm: SpurTracer 'System Map' View
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

package MapView;

use Stats;
use AlarmMonitor;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $stats = new Stats($this->{'intervalName'});
	my %results;

	my $filter = $this->{'glob'}{'type'};
	$filter = "global" unless(defined($filter));

	my @objectTypes = ('Host', 'Component', 'Interface');
	@objectTypes = (ucfirst($filter)) if($filter ne "global");

	@instanceTypes = @objectTypes;
	@instanceTypes = ('Component') if($filter eq "host");

	foreach my $type (@objectTypes) {
		$results{"${type}s"}		= $stats->get_object_list(lc($type));
	}
	foreach my $type (@instanceTypes) {
		$results{"${type}Instances"}	= $stats->get_instance_list(lc($type));
	}

	my @match;

	if($filter ne "global") {
		@keys = @{$stats->get_keys(('object', $filter))};
	} else {
		@keys = ('object!global');
	}

	foreach my $key (@keys) {
		my (%objStat, $match);

		if($filter eq 'global') {
			$objStat{'name'} = 'Global Events';
			$match = 'object!global';
		} elsif($key =~ /^stats[^!]*!(object!$filter!([^!]+))!started$/) {
			$objStat{'name'} = ucfirst($filter)." $2";
			$match = $1;
		} else {
			next;
		}

		$objStat{'counters'} = $stats->get_interval($match, 100, ("started", "failed", "announced", "timeout"));
		$objStat{'interval'} = $stats->{'interval'}->{'name'};
		push(@{$results{'Statistics'}}, \%objStat);
	}

	$results{'Alarms'} = alarm_monitor_get_alarms();

	$this->{'results'} = \%results;

	return bless $this, $type;
}

1;
