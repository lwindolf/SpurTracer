# Settings.pm: SpurTracer Settings Data Access
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

package Settings;

use warnings;
use strict;
use DB;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	settings_get_defaults
	settings_get_all
	settings_get
	settings_get_specific
	settings_add
	settings_remove
);

my %DEFAULT_SETTINGS = (
	'nagios' => {
		'server' => {
			'NSCAHost'	=> 'localhost',
			'NSCAPort'	=> 5667,
			'NSCAClientPath' => '/usr/local/bin/send_nsca',
			'NSCAConfigFile' => '/usr/local/etc/nsca.conf'
		}
	},
	'timeouts' => {
		'global' => {
			'component' => 60,
			'interface' => 60
		}
	},
	'alarms' => {
		'global.Error Rate' => {
			'critical' => 15,
			'warning' => 7
		},
		'global.Timeout Rate' => {
			'critical' => 6,
			'warning' => 3
		},
	},
	'spuren' => {
		'global' => {
			'ttl' => 3600 * 24
		}
	}
);

################################################################################
# Returns a list of all default settings
################################################################################
sub settings_get_defaults {
	my @results = ();

	foreach my $prefix (keys %DEFAULT_SETTINGS) {
		foreach my $name (keys %{$DEFAULT_SETTINGS{$prefix}}) {
			$DEFAULT_SETTINGS{$prefix}{$name}{'prefix'} = $prefix;
			$DEFAULT_SETTINGS{$prefix}{$name}{'name'} = $name;
			push(@results, $DEFAULT_SETTINGS{$prefix}{$name});
		}
	}

	return \@results;
}

################################################################################
# Generic settings getter.
#
# $1	Namespace Prefix (optional)
#
# Returns a list of all settings
################################################################################
sub settings_get_all {
	my ($prefix) = @_;
	my @results = ();

	$prefix = "*" unless(defined($prefix));

	foreach my $key (DB->keys("settings!$prefix!*")) {
		my %tmp = DB->hgetall($key);
		push(@results, \%tmp);
	}

	return \@results;
}

################################################################################
# Settings getter for hierarchic settings. Returns the first matching setting.
#
# ($1,$2)	Filter list (prefix, name)
#
# Returns a single hash reference (or undef)
################################################################################
sub settings_get_specific {
	my ($prefix) = shift;
	my $path = join("!", @_);

	# Try to fetch exactly matching setting
	foreach my $key (DB->keys("settings!$prefix!$path")) {
		my %tmp = DB->hgetall($key);
		return \%tmp;
	}

	# Determining inherited settings to be checked
	my @steps = ();

	if($path =~ /^instance!interface!(\w+)!(\w+)!(\w+)$/) {
		push(@steps, "object!interface!$2!$3");
		push(@steps, "object!host!$1");
	}
	if($path =~ /^instance!component!(\w+)!(\w+)$/) {
		push(@steps, "object!component!$2");
		push(@steps, "object!host!$1");
	}
	if($path =~ /^object!interface!(\w+)!(\w+)$/) {
		push(@steps, "object!component!$1");
	}
	if($path =~ /^object!component!(\w+)!(\w+)$/) {
		push(@steps, "object!host!$1");
	}

	foreach my $key (@steps) {
		foreach my $key (DB->keys("settings!$prefix!$key")) {
			my %tmp = DB->hgetall($key);
			return \%tmp;
		}
	}

	# Give up
	return undef;
}

################################################################################
# Generic settings getter. Returns the first matching setting
#
# ($1,$2)	Filter list (prefix, name)
#
# Returns a single hash reference (or undef)
################################################################################
sub settings_get {
	my ($prefix, $name) = @_;
	my $filter = join("!", @_);

	foreach my $key (DB->keys("settings!$filter")) {
		next unless($key =~ /^[\w!]+$/);
		my %tmp = DB->hgetall($key);
		return \%tmp;
	}

	# Check for default value...
	if(defined($DEFAULT_SETTINGS{$prefix}{$name})) {
		return $DEFAULT_SETTINGS{$prefix}{$name};
	}

	return undef;
}

################################################################################
# Generic settings setter.
#
# $1	hash of query parameters
################################################################################
sub settings_add {
	my %glob = @_;

	return unless(defined($glob{'prefix'}) &&
	              defined($glob{'name'}));

	foreach my $key (keys %glob) {
		DB->hset("settings!$glob{prefix}!$glob{name}", $key, $glob{$key});
	}
}

################################################################################
# Generic settings removal.
#
# $1	Redis handle
# $2	hash of query parameters
################################################################################
sub settings_remove {
	my %glob = @_;

	return unless(defined($glob{'prefix'}) &&
	              defined($glob{'name'}));

	DB->del("settings!$glob{prefix}!$glob{name}");
}

1;

=head1 Settings - General Configuration Support of SpurTracer

=head2 Concept

=begin text

Settings for different groups of functionality in SpurTracer
are grouped by setting namespace prefixes. This allows Nagios
settings to coexist with alarm settings etc. A single setting
key has a hash of properties assigned which may have different
meanings for different setting namespaces.

The Setting class helps accessing single or all namespace keys
and returns them as Perl hashes or a list of hashes. Additionally
it provides a setting hierarchy aware access method to retrieve
statistic object specific settings.

=end text

=head2 Which Getter Method is The Right One?

=begin text

To fetch a single setting that 100% exists
	-> settings_get()

To fetch a statistics object setting
	-> settings_get_specific()

To fetch all settings with the same namespace prefix
	-> settings_get_all()

To fetch all hard coded defaults
	-> settings_get_defaults()

=end text

=cut
