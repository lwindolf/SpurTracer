# SettingsView.pm: SpurTracer 'Settings' View
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


package SettingsView;

use Settings;
use Stats;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	foreach my $type ('Host', 'Interface', 'Component') {
		$results{"${type}s"}		= stats_get_object_list($spuren->{redis}, lc($type));
		$results{"${type}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($type));
	}
	$results{'Settings'} = settings_get_all($spuren->{redis});
	$this->{results} = \%results;

	return bless $this, $type;
}

1;
