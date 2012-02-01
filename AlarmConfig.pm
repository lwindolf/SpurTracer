# AlarmConfig.pm: SpurTracer Alarm Configuration
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

package AlarmConfig;

require Exporter;

use Settings;

@ISA = qw(Exporter);

@EXPORT = qw(alarm_config_get);

# Default error rate alarm configuration (in %)
my %DEFAULT_ALARM_THRESHOLDS = (
	'critical'	=> 15,
	'warning'	=> 5	
);

################################################################################
# Get most specific alarm config value for a given object name
#
# $1	object name
#
# Returns alarm threshold config hash
################################################################################
sub alarm_config_get {
	my ($object) = @_;

	my $settings = settings_get("alarms", "global");
	return $settings if(defined($settings));

	# If nothing else can be found return default config
	return \%DEFAULT_ALARM_THRESHOLDS;
}

1;

__END__

=head1 AlarmConfig - Configuration of Alarm Threshold

=head2 Hierarchical Definitions

=begin text

To allow configuring individual alarm threshold alarms can
be defined per object. This class hides the configuration complexity
by providing a simple alarm config getter. This getter returns a
alarm config hash that includes the different alarm thresholds.

The alarm config hash is determined hierarchically from global
settings down to object specific settings with the more specific
ones overruling the defaults.

=end text

=head2 Configuration Interface

=begin text

To allow the end user configuring alarm thresholds we provide
a configuration interface querying existing configurations and
allowing to delete existing or add new ones.

=end text

=cut
