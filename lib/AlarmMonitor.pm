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

use strict;
use warnings;
use Announcement;
use AlarmConfig;
use DB;
use Settings;
use Spuren;
use Stats;

our @ISA = qw(Exporter);

our @EXPORT = qw(alarm_monitor_create alarm_monitor_get_alarms);

$ENV{ 'PATH' } = '';
$ENV{ 'ENV' } = '';

my $INTERVAL = 10;	# for now run detection roughly every 10s

my @CHECK_TYPES = (	# currently known check types
	'Error Rate',
	'Timeout Rate'
);

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
	$this->{'spuren'} = new Spuren();

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
# $2	object name
# $3	check type ('Error Rate' or 'Timeout Rate')
#
# Returns 
# -> status code (0=ok, 1=warning, 2=critical, 3=unknown)
# -> the configured threshold that was surpassed (or 0)
# -> the error rate
# -> a Nagios performance data string
################################################################################
sub _check_object {
	my ($this, $object, $check) = @_;

	return (3, 0, 0, "") unless($object->{'started'} > 0);

	# map check types to counter
	my %counter = (
		'Error Rate' => 'failed',
		'Timeout Rate' => 'timeout'
	);
	my %config = %{alarm_config_get_threshold($check, $object->{'key'})};
	my $rate = $object->{$counter{$check}} * 100 / $object->{'started'};;
	my $perfdata = sprintf "$check=%0.2f%%;%0.2f%%;%0.2f%%;", $rate, $config{'warning'}, $config{'critical'};

	return (2, $config{'critical'}, $rate, $perfdata) if($rate >= $config{'critical'});
	return (1, $config{'warning'},  $rate, $perfdata) if($rate >= $config{'warning'});
	return (0, 0, $rate, $perfdata);
}

################################################################################
# Check wether we need to raise some alarms and add alarms to alarm list
################################################################################
sub _check {
	my $this = shift;
	my $now = time();

	# Check object error/timeout rates
	foreach my $check (@CHECK_TYPES) {
		foreach my $type ('host', 'component', 'interface') {
			foreach my $object (@{$this->{'stats'}->get_object_list($type)}) {
				my ($status, $threshold, $rate) = $this->_check_object($object, $check);
			
				if($status > 0 and $status < 3) {
					$this->_add_alarm(($status > 1)?'critical':'warning', $type, $object->{'name'}, sprintf("%s is %0.2f%% (> %d%% threshold)!", $check, $rate, $threshold));
					next;
				}
			}	
		}
	}

	# Check overdue announcements (uncleared older announcements)
	foreach my $announcement (@{announcements_fetch('interface', {})}) {
		next if($announcement->{'timeout'} == 1);

		my $timeoutSetting = alarm_config_get_timeout("instance!interface!$announcement->{host}!$announcement->{component}!$announcement->{newcomponent}");
		next if(($now - $announcement->{'time'}) < $timeoutSetting->{'interface'});

		$this->{'spuren'}->add_timeout('interface', $announcement);
	}

	# Check component timeouts (missing 'finished' event)
	foreach my $announcement (@{announcements_fetch('component', {})}) {
		next if($announcement->{'timeout'} == 1);

		my $timeoutSetting = alarm_config_get_timeout("instance!component!$announcement->{host}!$announcement->{component}");
		next if(($now - $announcement->{'time'}) < $timeoutSetting->{'component'});

		$this->{'spuren'}->add_timeout('component', $announcement);
	}

	# Cleanup 'events' ZSET by event TTL
	my $settings = settings_get("spuren", "global");
	my $total = DB->zcard('events');
	my $removed = DB->zremrangebyscore('events', 0, ($now - $settings->{'ttl'}) * 1000);
	#print STDERR "Cleanup $removed of $total events (TTL=$settings->{ttl}) age < ".(($now - $settings->{'ttl'})*1000)."\n";
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
	$last = 0 unless(defined($last));
	return if(($now - $last) < 60);

	my $nagios = settings_get("nagios", "server");
	return unless(defined($nagios->{'NSCAClientPath'}));

	my $cmd = $nagios->{'NSCAClientPath'} . " ";
	$cmd .= "-d '!' ";
	$cmd .= "-H $nagios->{NSCAHost} ";
	$cmd .= "-p $nagios->{NSCAPort} "	if($nagios->{'NSCAPort'} ne "");
	$cmd .= "-c $nagios->{NSCAConfigFile} "	if($nagios->{'NSCAConfigFile'} ne "");

	print STDERR "Processing NSCA $now\n";
	foreach my $check (@CHECK_TYPES) {
		print STDERR "Processing $check checks...\n";
		foreach my $setting (@{settings_get_all("nagios.serviceChecks.$check")}) {
			# FIXME: Support instances!!!
			next unless($setting->{'name'} =~ /^object!((\w+)!.*)/);
			my $objectName = $1;
			my $objectType = $2;

			# Respect passive check interval
			$last = DB->get("alarmmonitor!$objectName!lastNSCASend");
			$last = 0 unless(defined($last));
			next if(($now - $last) < $setting->{'checkInterval'} * 60);
			DB->set("alarmmonitor!$objectName!lastNSCASend", $now);

			my %object = $this->{'stats'}->get_object($objectName);
			my ($status, $threshold, $rate, $perfdata) = $this->_check_object(\%object, $check);
			my $result = "";
			
			if($status == 0) {
				$result = sprintf "Current $check %0.2f%%", $rate;
			} elsif($status == 3) {
				$result = "No statistics for object '$objectName' [yet]!";
				$perfdata = "";
			} else {
				$result = sprintf "$check %0.2f%% (> %0.2f%% threshold)", $rate, $threshold;
			}

			print STDERR "$cmd\n";
			if(open(SEND_NSCA, "| $cmd >/dev/null")) {
				print STDERR "$setting->{mapHost}!$setting->{mapService}!$status!$result|$perfdata\n";
				print SEND_NSCA "$setting->{mapHost}!$setting->{mapService}!$status!$result|$perfdata\n";
				close(SEND_NSCA);
			} else {
				print STDERR "Failed to run '$cmd' ($!)\n";
			}
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
