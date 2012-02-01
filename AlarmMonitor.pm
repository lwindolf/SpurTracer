# AlarmMonitor.pm: Detect and forward alarms
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

package AlarmMonitor;

require Exporter;

use AlarmConfig;
use DB;
use Settings;
use Spuren;
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
		my $am = new AlarmMonitor();
		$am->_run();
		exit();
	}
}

sub new {
	my ($type) = @_;
	my $this = { };

	return bless $this, $type;
}

################################################################################
# Execute alarm monitor by running in a loop periodically performing the 
# alarm detection...
################################################################################
sub _run {
	my $this = shift;

	$this->{'stats'} = new Stats();

	while(1) {
		sleep($INTERVAL);

		# Force reconnect each time to avoid loosing the DB connection
		DB->reconnect();

		$this->_check();
		$this->_send_nsca();
	}
}

################################################################################
# Add a new alarm to the alarm sets in the DB. Overwrites old entries of the
# same object (so an new error will overwrite an previous warning). Sets a
# timeout for errors to disappear again.
#
# $2	severity ('error' or 'warning')
# $3	object type
# $4	message (without trailing \n)
################################################################################
sub _add_alarm {
	my ($this, $severity, $type, $name, $msg) = @_;

	my $key = "alarm!$type!$name";
	DB->hset($key, 'message', $msg);
	DB->hset($key, 'time', time());
	DB->hset($key, 'severity', $severity);
	DB->expire($key, $INTERVAL * 10);
}

################################################################################
# Check wether we need to raise some alarms and add alarms to alarm list
################################################################################
sub _check {
	my $this = shift;
	my $now = time();

	# Check error rates
	foreach my $type ('host', 'component', 'interface') {
		foreach my $object (@{$this->{'stats'}->get_object_list($type)}) {
			my %config = %{alarm_config_get($object)};
			my $errorRate = $$object{'failed'} * 100 / $$object{'started'};
			
			if($errorRate > $config{'critical'}) {
				$this->_add_alarm('error', $type, $$object{'name'}, sprintf("Error rate is %0.2f%% (> $config{critical}% threshold)!", $errorRate));
				next;
			}

			if($errorRate > $config{'warning'}) {
				$this->_add_alarm('warning', $type, $$object{'name'}, sprintf("Error rate is %0.2f%% (> $config{warning}% threshold)!", $errorRate));
				next;
			}
		}	
	}

	# Check overdue announcements (uncleared older announcements)
	my $spuren = new Spuren();
	my $timeoutSetting = settings_get("timeouts", "global");	# FIXME: Allow object specific setting
	foreach my $announcement (@{$spuren->fetch_announcements({})}) {
		next if($announcement->{'timeout'} == 1);
		next if(($now - $announcement->{'time'}) < $timeoutSetting->{'interface'});

		$spuren->set_announcement_timeout(%{$announcement});
		$this->{'stats'}->add_interface_timeout($announcement->{'sourceHost'},
		                                        $announcement->{'sourceComponent'},
		                                        $announcement->{'component'});
	}

	# Check component timeouts (missing 'finished' event)
	# FIXME
}

################################################################################
# Check wether we need to send service check results to Nagios
################################################################################
sub _send_nsca {
	my $this = shift;
	my $now = time();

	# Check last NSCA processing time stamp to determine wether we have
	# new sending to do. Minimal update interval for NSCA is 60s.
	my $last = DB->get("alarmmonitor!lastNSCASend");
	return if(($now - $last) < 60);

	my $nagios = settings_get("nagios", "server");
	return unless(defined($nagios->{'NSCAClientPath'}));

	#print STDERR "Processing NSCA " .time() . "\n";
	foreach my $setting (@{settings_get_all("nagios.serviceChecks")}) {
		my $cmd = $nagios->{'NSCAClientPath'} . " ";
		$cmd .= "-H $nagios->{NSCAHost} ";
		$cmd .= "-p $nagios->{NSCAPort} "	if($nagios->{'NSCAPort'} ne "");
		$cmd .= "-c $nagios->{NSCAConfigFile} "	if($nagios->{'NSCAConfigFile'} ne "");
		#print STDERR "$cmd\n";
	}

	# Update last NSCA processing time stamp...
	DB->set("alarmmonitor!lastNSCASend", $now);
}

################################################################################
# Returns a list of all currently active alarms
################################################################################
sub alarm_monitor_get_alarms {
	my @results = ();

	foreach my $key (DB->keys("alarm!*!*")) {
		next unless($key =~ /^alarm!(\w+)!(\w+)$/);
		my ($type, $name) = ($1, $2);
		my %tmp = DB->hgetall($key);
		$tmp{'type'} = $type;
		$tmp{'name'} = $name;
		push(@results, \%tmp);
	}

	return \@results;
}

1;
