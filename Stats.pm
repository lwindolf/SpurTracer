# Helper methods for keeping per-object statistics

# The current simple key schema only allows tracking data for
#
# - per host name
# - per component name
# - per interface name (component1+component2)
#
# To be added in future versions:
#
# - per component instance (host+component)
# - per interface instance (host1+component1+host2+component2)

package Stats;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(stats_add_start_notification stats_add_error_notification stats_get_object stats_get_object_list);

################################################################################
# Generic counter method. Increases counter by 1.
#
# $1	Redis handle
# $2	object type ('interface', 'component' or 'host')
# $3	object name
# $4	event that is counted ('error', 'started' or 'timeout')
################################################################################
sub stats_count_object {
	my $redis = shift;
	my $key = join("::", @_);

	$redis->incr("stats::".$key);
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $1	Redis handle
# $2	Host
# $3	Component
################################################################################
sub stats_add_start_notification {

	stats_count_object($_[0], 'host', $_[1], 'started');
	stats_count_object($_[0], 'component', $_[2], 'started');

	# Todo: Also count starts for component instance
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $1	Redis handle
# $2	Host
# $3	Component
################################################################################
sub stats_add_error_notification {

	stats_count_object($_[0], 'host', $_[1], 'failed');
	stats_count_object($_[0], 'component', $_[2], 'failed');

	# Todo: Also count error for component instance
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $1	Redis handle
# $2	Source Host
# $3	Source Component
# $4	Target Host
# $5	Target Component
################################################################################
sub stats_add_interface_timeout {

	stats_count_object($_[0], 'interface', $_[2] . "::" . $_[4], 'timeout');

	# Todo: Also count error for interface instance
}

################################################################################
# Generic counter getter. Returns all interesting fields per object+type as
# a hash.
#
# $1	Redis handle
# $2	object type ('interface', 'component' or 'host')
# $3	object name
################################################################################
sub stats_get_object {
	my $redis = shift;
	my $key_prefix = join("::", @_);
	my %results = ();

	foreach(('error', 'started', 'timeout')) {
		$results{$_} = $redis->get($key_prefix . "::" . $_);
	}

	return %results;
}

################################################################################
# Get a list of all known objects of a type
#
# $1	Redis handle
# $2	object type ('interface', 'component' or 'host')
################################################################################
sub stats_get_object_list {
	my ($redis, $type) = @_;
	my @results = ();

	foreach($redis->keys("stats::$type::*")) {
		push(@results, $1) if(/stats::$type::(\w+)$/);
	}

	return @results;
}

1;
