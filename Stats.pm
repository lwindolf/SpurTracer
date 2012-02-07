# Stats.pm: Per-Object Counter Data Access
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

@EXPORT = qw(
	stats_get_default_interval
	stats_get_interval_definitions
);

my @INTERVALS = (
	{ 'name' => 'hour',	'resolution' => 60,	step => 60 },
	{ 'name' => 'day',	'resolution' => 24*60,	step => 60 },
	{ 'name' => 'week',	'resolution' => 7*144,	step => 600 },
	{ 'name' => 'year',	'resolution' => 365,	step => 24*60*60 }
);

################################################################################
# Constructor
#
# $1	interval (optional)
################################################################################
sub new {
	my ($type, $intervalName) = @_;
	my $this = { };

	# Try to find interval with given name
	foreach my $i (@INTERVALS) {
		if($$i{'name'} eq $intervalName) {
			$this->{'interval'} = $i;
			last;
		}
	}

	unless(defined($this->{'interval'})) {
		# Note: We expect @INTERVALS to be sorted from smallest to largest 
		# interval. The smallest one is considered default.
		$this->{'interval'} = $INTERVALS[0];
	}

	return bless $this, $type;
}

################################################################################
# Simple returns the interval definitions as an array
################################################################################
sub stats_get_interval_definitions {

	return \@INTERVALS;
}

################################################################################
# Simple returns the interval definitions as an array
################################################################################
sub stats_get_default_interval {

	return $INTERVALS[0];
}

################################################################################
# Generic interval counter method. Increases counter by 1 for all configured
# intervals. To be used by _count_object/interface() only.
#
# $2	Key
################################################################################
sub _count_interval {
	my ($this, $key) = @_;

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
		my $n = (time() / $$interval{step}) % ($$interval{resolution} + 1);
		
		DB->hsetnx("stats$$interval{name}\!$key", $n, 0);
		DB->hincrby("stats$$interval{name}\!$key", $n, 1);
		DB->hset("stats$$interval{name}\!$key", ($n + 1) % ($$interval{resolution} + 1), 0);
	}
}

################################################################################
# Generic interval counter query method. Returns an hash of all value slots.
#
# $2	Key 			(e.g. "object!component!comp2")
# $*	List of counters 	(e.g. ("started", "failed"))
################################################################################
sub get_interval {
	my $this = shift;
	my $key = shift;
	my @counters = @_;
	my %interval = %{$this->{'interval'}};
	my %results;

	# Skip unused 0 element at (n+1) used for ring buffer semantic from 
	# result by starting at (n+2) and wrapping around correctly...
	my $n = (time() / $interval{'step'}) % ($interval{'resolution'} + 1);

	$results{'name'} = $interval{'name'};

	foreach my $counter (@counters) {
		my %tmp = DB->hgetall("stats$interval{name}!$key!$counter");

		# Sort all elements, fill in missing zeros and output starting at
		# correct ring buffer offset n
		for($i = 0; $i < $interval{'resolution'}; $i++) {
			$results{$counter}{$i} = $tmp{(($n + 2 + $i) % ($interval{'resolution'} + 1))};
			$results{$counter}{$i} = 0 unless(defined($results{$counter}{$i}));
		}
	}

	return \%results;
}

################################################################################
# Generic object counter method. Increases counter by 1.
#
# $2	object type ('interface', 'component' or 'host')
# $3	object name
# $4	event that is counted ('error', 'started' or 'timeout')
################################################################################
sub _count_object {
	my $this = shift;
	my $key = join("!", @_);

	DB->incr("stats!object!$key");
	$this->_count_interval("object!$key");
}

################################################################################
# Generic instance counter method. Increases counter by 1.
#
# $2	object type ('interface', 'component')
# $3	object name
# $4	event that is counted ('error', 'started' or 'timeout')
################################################################################
sub _count_instance {
	my $this = shift;
	my $key = join("!", @_);

	DB->incr("stats!instance!".$key);
	$this->_count_interval("instance!$key");
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $2	Host
# $3	Component
################################################################################
sub add_start_notification {
	my $this = $_[0];

	$this->_count_object('global', 'started');
	$this->_count_object('host', $_[1], 'started');
	$this->_count_object('component', $_[2], 'started');

	$this->_count_instance('component', join("!", ($_[1], $_[2])), 'started');
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $2	Host
# $3	Component
################################################################################
sub add_error_notification {
	my $this = $_[0];

	$this->_count_object('global', 'failed');
	$this->_count_object('host', $_[1], 'failed');
	$this->_count_object('component', $_[2], 'failed');

	$this->_count_instance('component', join("!", ($_[1], $_[2])), 'failed');
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# $2	Source Host
# $3	Source Component
# $4	Target Component
################################################################################
sub add_interface_announced {
	my $this = $_[0];

	# Note: for a simpler and generic processing we use 'started'
	# instead of 'announced' as the counter name for interfaces...
	$this->_count_object('global', 'announced');
	$this->_count_object('interface', join("!", ($_[2], $_[3])), 'started');

	$this->_count_instance('interface', join("!", ($_[1], $_[2], $_[3])), 'started');
}

################################################################################
# Generic error counter method. Increases the error for all relevant counters.
#
# To be called only by AlarmMonitor!
#
# $2	Source Host
# $3	Source Component
# $5	Target Component
################################################################################
sub add_interface_timeout {
	my $this = $_[0];

	$this->_count_object('global', 'timeout');
	$this->_count_object('interface', $_[2] . "!" . $_[3], 'timeout');

	$this->_count_instance('interface', join("!", ($_[1], $_[2], $_[3])), 'timeout');
}

################################################################################
# Generic counter getter. Returns all interesting fields per object+type as
# a hash.
#
# $2	object type ('interface', 'component' or 'host')
# $3	object name
################################################################################
sub get_object {
	my $this = shift;
	my $key_prefix = join("!", @_);
	my %results = ();

	foreach(('failed', 'started', 'timeout', 'announced')) {
		$results{$_} = DB->get("stats!object!$key_prefix!$_");
		$results{$_} = 0 unless(defined($results{$_}));
	}

	return %results;
}

################################################################################
# Get a list of all known object keys of a type
#
# $2	type ('object' or 'instance')
# $3	value type ('global', 'interface', 'component' or 'host')
# $4	counter name (optional, defaults to 'started')
#
# Returns a list of key names
################################################################################
sub get_keys {
	my ($this, $type, $valueType, $counter) = @_;

	$counter = "started" unless(defined($counter));
	my @keys = DB->keys("stats!$type!$valueType!*!$counter");

	return \@keys;
}

################################################################################
# Get a list of all known objects of a type and their properties as returned
# by stats_get_object()
#
# $2	object type ('global', 'interface', 'component' or 'host')
#
# Returns a list including
#
#	('name' => '<hostname>') pairs for host and components
#	('from' => '<source component>',
#        'to'   => '<target component>) pairs for interfaces
################################################################################
sub get_object_list {
	my ($this, $type) = @_;
	my @results = ();

	foreach(@{$this->get_keys('object', $type)}) {
		next unless(/^stats!object!$type!(.+)!\w+$/);
		my %tmp = $this->get_object($type, $1);
		
		# We must distinguish between interfaces and other object
		# as interface names are <from>!<to> pairs...
		if($type eq "interface") {
			next unless($1 =~ /^([^!]+)!([^!]+)$/);
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
# $2	instance type ('interface', 'component')
# $3	instance name
################################################################################
sub get_instance {
	my $this = shift;
	my $key_prefix = join("!", @_);
	my %results = ();

	foreach(('failed', 'started', 'timeout', 'announced')) {
		$results{$_} = DB->get("stats!instance!$key_prefix!$_");
		$results{$_} = 0 unless(defined($results{$_}));
	}

	return %results;
}

################################################################################
# Get a list of all known objects of a type and their properties as returned
# by stats_get_instance()
#
# $2	object type ('interface', 'component')
#
# Returns a list of FIXME pairs
################################################################################
sub get_instance_list {
	my ($this, $type) = @_;
	my @results = ();

	foreach(@{$this->get_keys('instance', $type)}) {
		next unless(/^stats!instance!$type!(.+)!\w+$/);
		my %tmp = $this->get_instance($type, $1);

		# Split instance name into it's parts. E.g.
		#
		# 	host0!comp1		for a component instance
		#	host0!comp1!comp2	for an interface instance
		if($1 =~ /^([^!]+)!([^!]+)(!([^!]+))?$/) {
			$tmp{'host'} = $1;
			$tmp{'component'} = $2;
			$tmp{'newcomponent'} = $4 if(defined($4));
			push(@results, \%tmp); 
		}
	}

	return \@results;
}

1;
