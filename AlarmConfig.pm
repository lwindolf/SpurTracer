package AlarmConfig;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(alarm_config_get);

# Default error rate alarm configuration (in %)
my %DEFAULT_ERROR_ALARM_THRESHOLDS = (
	'error'		=> 15,
	'warning'	=> 5	
);

################################################################################
# Get most specific alarm config value for a given object name
#
# $1	Redis handle
# $2	object name
#
# Returns alarm threshold hash
################################################################################
sub alarm_config_get {
	my ($redis, $object) = @_;

	# FIXME: Read more specific config from Redis

	# If nothing else can be found return default config
	return \%DEFAULT_ERROR_ALARM_THRESHOLDS;
}

1;

__END__

=head1 AlarmConfig - Configuration of Alarm Threshold

=head2 Hierachical Definitions

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
