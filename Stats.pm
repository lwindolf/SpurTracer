# Helper methods for keeping per-object statistics

# The current simple key schema only allows tracking data for
#
# - per host name
# - per component name
# - per component instance (host+component)
# - per interface name (component1+component2)
# - per interface instance (host1+component1+component2)

package Stats;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(stats_add_start_notification stats_add_error_notification stats_add_interface_announced stats_add_interface_timeout stats_get_object stats_get_object_list);

################################################################################
# Generic object counter method. Increases counter by 1.
#
# $1	Redis handle
# $2	object type ('interface', 'component' or 'host')
# $3	object name
# $4	event that is counted ('error', 'started' or 'timeout')
################################################################################
sub stats_count_object {
	my $redis = shift;
	my $key = join("::", @_);

	$redis->incr("stats::object::".$key);
}

################################################################################
# Generic instance counter method. Increases counter by 1.
#
# $1	Redis handle
# $2	object type ('interface', 'component')
# $3	object name
# $4	event that is counted ('error', 'started' or 'timeout')
################################################################################
sub stats_count_instance {
	my $redis = shift;
	my $key = join("::", @_);

	$redis->incr("stats::instance::".$key);
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

	stats_count_instance($_[0], 'component', join("::", ($_[1], $_[2])), 'started');
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

	stats_count_instance($_[0], 'component', join("::", ($_[1], $_[2])), 'failed');
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $1	Redis handle
# $2	Source Host
# $3	Source Component
# $4	Target Component
################################################################################
sub stats_add_interface_announced {

	# Note: for a simpler and generic processing we use 'started'
	# instead of 'announced' as the counter name...

	stats_count_object($_[0], 'interface', join("::", ($_[2], $_[3])), 'started');

	stats_count_instance($_[0], 'interface', join("::", ($_[1], $_[2], $_[3])), 'started');
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

	stats_count_instance($_[0], 'interface', join("::", ($_[1], $_[2], $_[3], $_[4])), 'timeout');
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
		$results{$_} = $redis->get("stats::object::" . $key_prefix . "::" . $_);
		$results{$_} = 0 unless(defined($results{$_}));
	}

	return %results;
}

################################################################################
# Get a list of all known objects of a type and their properties as returned
# by stats_get_object()
#
# $1	Redis handle
# $2	object type ('interface', 'component' or 'host')
#
# Returns a list of ('name' => '<hostname>') pairs
################################################################################
sub stats_get_object_list {
	my ($redis, $type) = @_;
	my @results = ();

	foreach($redis->keys("stats::object::".$type."::*::started")) {
		next unless(/^stats::object::$type\:\:(.+)::\w+$/);
		my %tmp = stats_get_object($redis, $type, $1);
		$tmp{'name'} = $1;
		push(@results, \%tmp); 

	}

	return \@results;
}

1;
