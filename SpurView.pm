# SpurView.pm: View for everything regarding one or more spurs
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

package SpurView;

use AlarmMonitor;
use Spuren;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my $stats = new Stats($this->{'glob'}{'interval'});
	my %results;

	$results{'Spuren'} = $spuren->fetch(%{$this->{glob}});
	$results{'Alarms'} = alarm_monitor_get_alarms();

	foreach	my $object (keys %{$this->{'glob'}}) {
		next unless($object =~ /^(host|component)$/);
		$results{'IntervalStatistics'} = $stats->get_interval("object!$object!$this->{glob}{$object}", 100, ('started', 'failed'));
	}

	$this->{'results'} = \%results;

	return bless $this, $type;
}

1;
