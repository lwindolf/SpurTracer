# Helper methods for keeping per-object statistics

# The current simple key schema only allows tracking data for
#
# - per host name
# - per component name
# - per component instance (host+component)
# - per interface name (component1+component2)
# - per interface instance (host1+component1+component2)
#
# These counters are kept for different intervals using one
# Redis ZSET for each interval. 

package Stats;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(stats_add_start_notification stats_add_error_notification stats_add_interface_announced stats_add_interface_timeout stats_get_object stats_get_object_list stats_get_instance_list stats_get_interval stats_get_interval_definitions);

my @INTERVALS = (
	{ 'name' => 'hour',	'resolution' => 60,	step => 60 },
	{ 'name' => 'day',	'resolution' => 24*60,	step => 60 },
	{ 'name' => 'week',	'resolution' => 7*144,	step => 600 },
	{ 'name' => 'year',	'resolution' => 365,	step => 24*60*60 }
);

################################################################################
# Simple returns the interval definitions as an array
################################################################################
sub stats_get_interval_definitions {
	return @INTERVALS;
}

################################################################################
# Generic interval counter method. Increases counter by 1 for all configured
# intervals. To be used by stats_count_object/interface() only.
#
# $1	Redis handle
# $2	Key
################################################################################
sub stats_count_interval {
	my ($redis, $key) = @_;

	# Writing to an interval set of resolution m at time slot n
	# is done by incrementing slot n and resetting slot n+1
	# based on server time where
	#
	#	n = time() % m
	#	m = interval resolution + 1
	#
	# The resulting error rate is the sum of all values in
	# the interval array. The array (excluding the n+1) field
	# can be used for a graphical
	foreach $interval (@INTERVALS) {
		# All interval sizes are minute based: so 1000*60
		my $n = (time() / $$interval{step}) % ($$interval{resolution} + 1);
		
		$redis->hsetnx("stats$$interval{name}\::$key", $n, 0);
		$redis->hincrby("stats$$interval{name}\::$key", $n, 1);
		$redis->hset("stats$$interval{name}\::$key", ($n + 1) % ($$interval{resolution} + 1), 0);
	}
}

################################################################################
# Generic interval counter query method. Returns an hash of all value slots.
#
# $1	Redis handle
# $2	Key
################################################################################
sub stats_get_interval {
	my ($redis, $intervalName, $key) = @_;
	
	my %tmp = $redis->hgetall("stats${intervalName}\::$key");

	# Get interval definition
	my $interval;
	foreach my $i (@INTERVALS) {
		if($$i{'name'} eq $intervalName) {
			$interval = $i;
			last;
		}
	}

	return undef unless(defined($interval));

	# Skip unused 0 element at (n+1) used for ring buffer semantic from 
	# result by starting at (n+2) and wrapping around correctly...
	my $n = (time() / $$interval{step}) % ($$interval{resolution} + 1);

	# Sort all elements, fill in missing zeros and output starting at
	# correct ring buffer offset n
	my %results;
	for($i = 0; $i < $$interval{'resolution'}; $i++) {
		$results{$i} = $tmp{(($n + 2 + $i) % ($$interval{resolution} + 1))};
		$results{$i} = 0 unless(defined($results{$i}));
	}

	return \%results;
}

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

	$redis->incr("stats::object::$key");
	stats_count_interval($redis, "object::$key");
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
	stats_count_interval($redis, "instance::$key");
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $1	Redis handle
# $2	Host
# $3	Component
################################################################################
sub stats_add_start_notification {

	stats_count_object($_[0], 'global', 'started');
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

	stats_count_object($_[0], 'global', 'failed');
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
	# instead of 'announced' as the counter name for interfaces...
	stats_count_object($_[0], 'global', 'interface', 'announced');
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

	stats_count_object($_[0], 'global', 'interface', 'timeout');
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

	foreach(('failed', 'started', 'timeout')) {
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
# $2	object type ('global', 'interface', 'component' or 'host')
#
# Returns a list of ('name' => '<hostname>') pairs
################################################################################
sub stats_get_object_list {
	my ($redis, $type) = @_;
	my @results = ();

	foreach($redis->keys("stats::object::".$type."::*::started")) {
		next unless(/^stats::object::$type\:\:(.+)::\w+$/);
		my %tmp = stats_get_object($redis, $type, $1);
		
		# We must distinguish between interfaces and other object
		# as interface names are <from>::<to> pairs...
		if($type eq "interface") {
			next unless($1 =~ /^([^:]+)::([^:]+)$/);
			$tmp{'from'} = $1;
			$tmp{'to'} = $2;
		} else {
			$tmp{'name'} = $1;
		}
		push(@results, \%tmp); 

	}

	return \@results;
}

################################################################################
# Generic counter getter. Returns all interesting fields per instance+type as
# a hash.
#
# $1	Redis handle
# $2	instance type ('interface', 'component')
# $3	instance name
################################################################################
sub stats_get_instance {
	my $redis = shift;
	my $key_prefix = join("::", @_);
	my %results = ();

	foreach(('failed', 'started', 'timeout')) {
		$results{$_} = $redis->get("stats::instance::" . $key_prefix . "::" . $_);
		$results{$_} = 0 unless(defined($results{$_}));
	}

	return %results;
}

################################################################################
# Get a list of all known objects of a type and their properties as returned
# by stats_get_instance()
#
# $1	Redis handle
# $2	object type ('interface', 'component')
#
# Returns a list of FIXME pairs
################################################################################
sub stats_get_instance_list {
	my ($redis, $type) = @_;
	my @results = ();

	foreach($redis->keys("stats::instance::".$type."::*::started")) {
		next unless(/^stats::instance::$type\:\:(.+)::\w+$/);
		my %tmp = stats_get_instance($redis, $type, $1);

		# Split instance name into it's parts. E.g.
		#
		# 	host0::comp1		for a component instance
		#	host0::comp1::comp2	for an interface instance
		if($1 =~ /^([^:]+)::([^:]+)(::([^:]+))?$/) {
			$tmp{'host'} = $1;
			$tmp{'component'} = $2;
			$tmp{'newcomponent'} = $4 if(defined($4));
			push(@results, \%tmp); 
		}
	}

	return \@results;
}

1;
