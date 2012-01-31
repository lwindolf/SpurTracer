# Settings.pm: SpurTracer Settings Data Access
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

package Settings;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	settings_get_all
	settings_get
	settings_add
	settings_remove
);


################################################################################
# Generic settings getter.
#
# $1	Redis handle
# $2	Namespace Prefix (optional)
#
# Returns a list of all settings
################################################################################
sub settings_get_all {
	my ($redis, $prefix) = @_;
	my @results = ();

	$prefix = "*" unless(defined($prefix));

	foreach my $key ($redis->keys("settings!$prefix!*")) {
		my %tmp = $redis->hgetall($key);
		push(@results, \%tmp);
	}

	return \@results;
}

################################################################################
# Generic settings getter. Returns the first matching setting
#
# $1		Redis handle
# ($2,$3)	Filter list (prefix, name)
#
# Returns a single hash reference (or undef)
################################################################################
sub settings_get {
	my $redis = shift;
	$filter = join("!", @_);

	foreach my $key ($redis->keys("settings!$filter")) {
		my %tmp = $redis->hgetall($key);
		return \%tmp;
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
	my $redis = Redis->new;

	return unless(defined($glob{'prefix'}) &&
	              defined($glob{'name'}));

	foreach my $key (keys %glob) {
		$redis->hset("settings!$glob{prefix}!$glob{name}", $key, $glob{$key});
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
	my $redis = Redis->new;

	return unless(defined($glob{'prefix'}) &&
	              defined($glob{'name'}));

	$redis->del("settings!$glob{prefix}!$glob{name}");
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
and returns them as Perl hashes or a list of hashes.

=end text

=cut
