# DB.pm: Redis static class singleton
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

package DB;

use warnings;
use strict;
use Redis;

my $redis;	# the DB instance

################################################################################
# Disconnect the DB.
################################################################################
sub disconnect {
	our $redis;

	$redis->quit()	if(defined($redis));
	$redis = undef;
}

################################################################################
# Reconnect the DB. Closes and reopens the DB
################################################################################
sub reconnect {
	our $redis;

	$redis->quit()	if(defined($redis));

	$redis = new Redis(encoding => undef);	# FIXME: allow different config

	# Check connection
	my $info = $redis->info();
	die "Could not connect to Redis! ($!)" unless($info->{'redis_version'});
}

################################################################################
# Check the DB connection and version
################################################################################
sub check {

	# Note: ping will auto-connect via auto loader
	ping() || die "Cannot ping Redis instance!";

	# Check Redis DB version, needs to be 1.3+ for hash support
	my $version = ${info()}{'redis_version'};
	$version =~ s/\.//;
	die "Redis version < 1.3 (is $version)!" unless($version ge 130);
	disconnect();
}

################################################################################
# Auto loader for all Redis methods
#
# Pass all undefined method names to the Redis package
# which will try to map them to Redis commands.
################################################################################
our $AUTOLOAD;

sub AUTOLOAD {
	no warnings;	# Redis causes many "untie attempted while 1 inner references still exist at /usr/local/share/perl/5.10.1/Net/Server.pm line 942, <GEN4> line 4"

	my $self = shift;
	our $redis;

	my $command = $AUTOLOAD;
	$command =~ s/.*://;

	reconnect() unless(defined($redis));

	eval "our \$redis;\$redis->$command(\@_);";
}

1;
