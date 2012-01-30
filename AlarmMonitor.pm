package AlarmMonitor;

require Exporter;

use AlarmConfig;
use Stats;

@ISA = qw(Exporter);

@EXPORT = qw(alarm_monitor_create alarm_monitor_get_alarms);

my $INTERVAL = 10;	# for now run detection roughly every 10s

################################################################################
# Start the alarm monitor by forking a background process
#
# Returns PID of new alarm monitor child process
################################################################################
sub alarm_monitor_create {

	my $pid = fork();
	unless(defined($pid)) {
		die "Failed to fork AlarmMonitor ($!)!";
	}

	if($pid) {
		print "Created AlarmMonitor (pid $pid)\n";
		return $pid;
	} else {
		alarm_monitor_run();
		exit();
	}
}

################################################################################
# Execute alarm monitor by running in a loop periodically performing the 
# alarm detection...
################################################################################
sub alarm_monitor_run {

	while(1) {
		sleep($INTERVAL);

		# Reopen Redis connection each time to avoid loosing it
		my $redis = Redis->new;
		next unless(defined($redis));

		alarm_monitor_check($redis);

		$redis->quit();
	}
}

################################################################################
# Add a new alarm to the alarm sets in Redis. Overwrites old entries of the
# same object (so an new error will overwrite an previous warning). Sets a
# timeout for errors to disappear again.
#
# $1	Redis handle
# $2	severity ('error' or 'warning')
# $3	object type
# $4	message (without trailing \n)
################################################################################
sub alarm_monitor_add_alarm {
	my ($redis, $severity, $type, $name, $msg) = @_;

	my $key = "alarm!$type!$name";
	$redis->hset($key, 'message', $msg);
	$redis->hset($key, 'time', time());
	$redis->hset($key, 'severity', $severity);
	$redis->expire($key, $INTERVAL * 10);
}

################################################################################
# Check wether we need to raise some alarms and add alarms to alarm list
################################################################################
sub alarm_monitor_check {
	my $redis = shift;

	# Check error rates
	foreach my $type ('host', 'component', 'interface') {
		foreach my $object (@{stats_get_object_list($redis, $type)}) {
			my %config = %{alarm_config_get($redis, $object)};
			my $errorRate = $$object{'failed'} * 100 / $$object{'started'};
			
			if($errorRate > $config{'error'}) {
				alarm_monitor_add_alarm($redis, 'error', $type, $$object{'name'}, sprintf("Error rate is %0.2f%% (> $config{error}% threshold)!", $errorRate));
				next;
			}

			if($errorRate > $config{'warning'}) {
				alarm_monitor_add_alarm($redis, 'warning', $type, $$object{'name'}, sprintf("Error rate is %0.2f%% (> $config{warning}% threshold)!", $errorRate));
				next;
			}
		}	
	}
}

################################################################################
# Returns a list of all currently active alarms
################################################################################
sub alarm_monitor_get_alarms {
	my $redis = shift;
	my @results = ();

	foreach my $key ($redis->keys("alarm!*!*")) {
		next unless($key =~ /^alarm!(\w+)!(\w+)$/);
		my ($type, $name) = ($1, $2);
		my %tmp = $redis->hgetall($key);
		$tmp{'type'} = $type;
		$tmp{'name'} = $name;
		push(@results, \%tmp);
	}

	return \@results;
}

1;
