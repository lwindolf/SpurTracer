# SpurenView.pm: Listing all known "Spuren" (call chain types)
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

package SpurenView;

use AlarmMonitor;
use Spuren;
use StatisticObject;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my %glob = %{$this->{'glob'}};
	my $stats = new Stats($glob{'interval'});
	my %results;

	$results{'Alarms'} = alarm_monitor_get_alarms();

	# We need all instance types as we want to display all their counters
	$results{"Interfaces"}		= $stats->get_object_list('interface');
	$results{"Components"}		= $stats->get_object_list('component');

	# Now we determine the existing interface chains. 
	# FIXME

	$this->{'results'} = \%results;

	return bless $this, $type;
}

1;
