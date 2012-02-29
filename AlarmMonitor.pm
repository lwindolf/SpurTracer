# AlarmMonitor.pm: Detect and forward alarms
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

package AlarmMonitor;

require Exporter;

use Announcement;
use AlarmConfig;
use DB;
use Settings;
use Stats;

@ISA = qw(Exporter);

@EXPORT = qw(alarm_monitor_create alarm_monitor_get_alarms);

$ENV{ 'PATH' } = '';
$ENV{ 'ENV' } = '';

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
# $2	severity ('critical' or 'warning')
# $3	object type
# $4	message (without trailing \n)
################################################################################
sub _add_alarm {
	my ($this, $severity, $type, $name, $msg) = @_;

	my $key = "alarm!$type!$name";
	DB->hset($key, 'message', $msg);
	DB->hset($key, 'time', time());
	DB->hsetnx($key, 'since', time());
	DB->hset($key, 'severity', $severity);
	DB->expire($key, $INTERVAL * 10);
}

################################################################################
# Check wether we need to raise some alarms and add alarms to alarm list
################################################################################
sub _check {
	my $this = shift;
	my $now = time();

	# Check object error rates
	foreach my $type ('host', 'component', 'interface') {
		foreach my $object (@{$this->{'stats'}->get_object_list($type)}) {
			my $key = "object!$type!$object->{name}";
			my %config = %{alarm_config_get_threshold($key)};
			my $errorRate = $object->{'failed'} * 100 / $object->{'started'};
			
			if($errorRate > $config{'critical'}) {
				$this->_add_alarm('critical', $type, $object->{'name'}, sprintf("Error rate is %0.2f%% (> $config{critical}%% threshold)!", $errorRate));
				next;
			}

			if($errorRate > $config{'warning'}) {
				$this->_add_alarm('warning', $type, $object->{'name'}, sprintf("Error rate is %0.2f%% (> $config{warning}%% threshold)!", $errorRate));
				next;
			}
		}	
	}

	# Check overdue announcements (uncleared older announcements)
	foreach my $announcement (@{announcements_fetch('interface', {})}) {
		next if($announcement->{'timeout'} == 1);

		my $timeoutSetting = alarm_config_get_timeout("instance!interface!$announcement->{host}!$announcement->{component}!$announcement->{newcomponent}");
		next if(($now - $announcement->{'time'}) < $timeoutSetting->{'interface'});

		announcement_set_timeout('interface', $announcement);
		$this->{'stats'}->add_interface_timeout($announcement->{'host'},
		                                        $announcement->{'component'},
		                                        $announcement->{'newcomponent'});
	}

	# Check component timeouts (missing 'finished' event)
	foreach my $announcement (@{announcements_fetch('component', {})}) {
		next if($announcement->{'timeout'} == 1);

		my $timeoutSetting = alarm_config_get_timeout("instance!component!$announcement->{host}!$announcement->{component}");
		next if(($now - $announcement->{'time'}) < $timeoutSetting->{'component'});

		announcement_set_timeout('component', $announcement);
		$this->{'stats'}->add_component_timeout($announcement->{'host'},
		                                        $announcement->{'component'});
	}
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

	my $cmd = $nagios->{'NSCAClientPath'} . " ";
	$cmd .= "-d '!' ";
	$cmd .= "-H $nagios->{NSCAHost} ";
	$cmd .= "-p $nagios->{NSCAPort} "	if($nagios->{'NSCAPort'} ne "");
	$cmd .= "-c $nagios->{NSCAConfigFile} "	if($nagios->{'NSCAConfigFile'} ne "");

	#print STDERR "Processing NSCA $now\n";
	foreach my $setting (@{settings_get_all("nagios.serviceChecks")}) {
		my $objectName = $setting->{'name'};

		# Respect passive check interval
		$last = DB->get("alarmmonitor!$objectName!lastNSCASend");
		next if(($now - $last) < $setting->{'interval'} * 60);
		DB->set("alarmmonitor!$objectName!lastNSCASend", $now);

		# FIXME: Support different types of checks (currently only error rate)
		my $status = 3;
		my $result = "";
		my $perfdata = "";
		$objectName =~ s/^object!//;
		my %object = $this->{'stats'}->get_object($objectName);
		my %config = %{alarm_config_get_threshold($setting->{'name'})};

		if($object{'started'} > 0) {
			my $errorRate = $object{'failed'} * 100 / $object{'started'};
			
			if($errorRate > $config{'critical'}) {
				$result = sprintf "Error Rate %0.2f%% (> %0.2f%% threshold)", $errorRate, $config{'critical'};
				$status = 2;
			} elsif($errorRate > $config{'warning'}) {
				$result = sprintf "Error Rate %0.2f%% (> %0.2f%% threshold)", $errorRate, $config{'warning'};
				$status = 1;
			} else {
				$result = sprintf "Current Error Rate %0.2f%%", $errorRate;
				$status = 0;
			}

			$perfdata = sprintf "error_rate=%0.2f%%", $errorRate;
		} else {
			$result = "No statistics for this object [yet]!\n";
		}

		if(open(SEND_NSCA, "| $cmd >/dev/null")) {
			print SEND_NSCA "$setting->{mapHost}!$setting->{mapService}!$status!$result|$perfdata\n";
			close(SEND_NSCA);
		} else {
			print STDERR "Failed to run '$cmd' ($!)\n";
		}
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
