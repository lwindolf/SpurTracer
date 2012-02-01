# DB.pm: Redis static class singleton
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

package DB;

use Redis;

my $redis;	# the DB instance

################################################################################
# Reconnect the DB. Closes and reopens the DB
################################################################################
sub reconnect {
	our $redis;

	$redis->quit()	if(defined($redis));

	$redis = new Redis();	# FIXME: allow different config

	# FIXME: Error handling
}

################################################################################
# Auto loader for all Redis methods
#
# Pass all undefined method names to the Redis package
# which will try to map them to Redis commands.
################################################################################
our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	our $redis;

	my $command = $AUTOLOAD;
	$command =~ s/.*://;

	reconnect() unless(defined($redis));

	eval "\$redis->$command(\@_);";
}

1;
