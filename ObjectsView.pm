# ObjectsView.pm: View for different object types
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


package ObjectsView;

use AlarmMonitor;
use Stats;

@ISA = (SpurTracerView);

################################################################################
# Constructor
################################################################################
sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $stats = new Stats();
	my %results;

	$this->{xslt} = $this->{objType};
	$this->{objType} =~ s/s$//;

	$results{"$this->{objType}s"}		= $stats->get_object_list(lc($this->{objType}));
	$results{"$this->{objType}Instances"}	= $stats->get_instance_list(lc($this->{objType}));
	$results{'Alarms'}			= alarm_monitor_get_alarms();

	$this->{results} = \%results;

	return bless $this, $type;
}

1;
