#!/usr/bin/perl -T

# Net::Server::HTTP based SpurTracer server
#
# Copyright (C) 2011 Lars Lindner <lars.lindner@gmail.com>
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

use strict;
use CGI;
use Redis;
use URI::Escape;
use Error qw(:try);
use POSIX qw(strftime);
use base qw(Net::Server::HTTP);
use lib ".";

use AlarmMonitor;
use Settings;
use Spuren;
use SpurQuery;

# Check Redis DB version, needs to be 1.3+ for hash support
#my $version = ${DB->info()}{'redis_version'};
#$version =~ s/\.//;
#die "Redis version < 1.3 (is $version)!" unless($version ge 130);
#DB->quit();

# Before starting the httpd fork a alarm monitor
# that runs in background to periodically perform
# checks and alarm detections
my $alarm_monitor_pid = alarm_monitor_create();

# Start httpd
__PACKAGE__->run;

my $debug = 1;

sub default_port { 8080 };

################################################################################
# Net::Server:HTTP initialization
#
# Setting up needed MIME types
################################################################################
sub configure_hook {
	my $self = shift;

	$self->{mime_types}    = {
		gif => 'image/gif',
		jpg => 'image/jpeg',
		png => 'image/png',
		css => 'text/css',
		xsl => 'application/xslt+xml',
		js => 'application/javascript'
	};
	$self->{mime_default} = 'text/plain';
}

################################################################################
# Data submission request handler
#
# $2	HTTP URI paramaters
################################################################################
sub process_data_submission {
	my ($this, $data) = @_;

	# Prepare data access
	my $spuren = new Spuren();

	my %data;
	foreach(split(/\&/, $data)) {
		if(/(\w+)=(.+)/) {
			my $key = $1;
			$data{$key} = $2;
			$data{$key} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			$data{$key} =~ s/\+/ /g;
		}
	}

	# Check for mandatory fields
	unless(defined($data{host}) &&
	       defined($data{component}) &&
	       defined($data{type}) &&
	       defined($data{ctxt}) &&
	       defined($data{time})) {

		$this->send_status(400);
		print "Content-type: text/plain\r\n\r\n";
		print "Invalid data submission!";

		if($debug) {
			print STDERR "Invalid data submission. Only the following fields where given:\n";
			foreach (keys(%data)) {
				print STDERR "	$_ => $data{$_}\n";
			}
		}
		return;
	}

	# FIXME: Validate important fields!


	if($spuren->add_data(%data) == 0) {
		$this->send_status(200);
		print "Content-type: text/plain\r\n\r\n";
		print "OK";
	} else {
		$this->send_status(400);
		print "Content-type: text/plain\r\n\r\n";
		print "Adding data failed!";
	}
}


################################################################################
# Settings request handler
#
# $2	HTTP URI parameters
# $3	request mode
################################################################################
sub process_settings_query {
	my ($this, $query, $mode) = @_;
	my %glob = ();

	if(defined($query)) {
		# Decode filtering fields if we got some
		foreach(split(/\&/, $query)) {
			if(/(\w+)=(.+)/) {
				my $key = $1;
				$glob{$key} = $2;
				$glob{$key} =~ s/\+/ /g;
				$glob{$key} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
			}
		}
	}

	# Process settings change
	if($mode eq "add") {
		settings_add(%glob);
	} elsif($mode eq "remove") {
		settings_remove(%glob);
	}

	# Run the Settings view...
	$this->process_query("", "getSettings");
}

################################################################################
# Generic data query request handler
#
# $2	HTTP URI parameters
# $3	request mode
################################################################################
sub process_query {
	my ($this, $query, $mode) = @_;
	my %glob = ();

	if(defined($query)) {
		# Decode filtering fields if we got some
		foreach(split(/\&/, $query)) {
			$glob{$1} = $2 if(/(\w+)=(.+)/);
		}
	}

	try {
		my $query = new SpurQuery($mode, %glob);
		$this->send_status(200);
		$query->execute();
	} catch Error with {
		$this->send_status(400);
		print "Content-type: text/plain\r\n\r\n";
		print "Invalid query";
	}
}

################################################################################
# HTTP error message helper
################################################################################
sub send_error {
	my ($self, $n, $msg) = @_;
	$self->send_status($n);
	print "Content-type: text/html\r\n\r\n";
	print "<h1>Error $n</h1><h3>$msg</h3>";
}

################################################################################
# Net::Server:HTTP request handler hook
#
# Distinguishes between
#
#   - data submission
#   - data queries
#   - static content (XSLT, CSS, images)
################################################################################
sub process_http_request {
	my $self = shift;

	#if (require Data::Dumper) {
	#	local $Data::Dumper::Sortkeys = 1;
	#	my $form = {};
	#	if (require CGI) {  my $q = CGI->new; $form->{$_} = $q->param($_) for $q->param;  }
	#	print "<pre>".Data::Dumper->Dump([\%ENV, $form], ['*ENV', 'form'])."</pre>";
	#}

	# Sanity check requests
	my $uri = $ENV{'PATH_INFO'} || '';
	if ($uri =~ /[\ \;]/) {
		return $self->send_error(400, "Malformed URL");
	}
	$uri =~ s/%(\w\w)/chr(hex($1))/eg;
	1 while $uri =~ s|^\.\./+||; # can't go below doc root

	$uri =~ s/^\/+//;	# strip leading slash

	# Handle static content (currently only XSLT, JS and CSS)
	if ($uri =~ m#^(xslt/\w+\.xsl|css/\w+\.css|js/[\w_.\-]+\.js)$#) {
		unless (-f $uri) {
			return $self->send_error(400, "Malformed URL");
		} else {
			$self->send_status(200);
			open(my $fh, '<', $uri) || return $self->send_501("Can't open file [$!]");
			my $type = $uri =~ /([^\.]+)$/ ? $1 : '';
			$type = $self->{'mime_types'}->{$type} || $self->{'mime_default'};
			print "Cache-Control: max-age=3600, public\r\n";
			print "Expires: ".strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime(time()+3600))."\r\n";
			print "Content-type: $type\r\n\r\n";
			print $_ while read $fh, $_, 8192;
			close $fh;
			return;
		}
	}

	# Handle get/set requests...
	if ($uri eq "set") {
		$self->process_data_submission($ENV{'QUERY_STRING'});
	} elsif ($uri eq "") {
		$self->process_query($ENV{'QUERY_STRING'}, 'Map');
	} elsif ($uri =~ /^(get\w*)$/) {
		$self->process_query($ENV{'QUERY_STRING'}, $1);
	} elsif ($uri eq "getAnnouncements") {
		$self->process_query($ENV{'QUERY_STRING'});
	} elsif ($uri =~ /^(add|remove)Setting$/) {
		$self->process_settings_query($ENV{'QUERY_STRING'}, $1);
	} else {
		return $self->send_error (404, "$uri not found!");
	}
}

################################################################################
# Net::Server shutdown hook
################################################################################
sub pre_server_close_hook {

	kill $alarm_monitor_pid;
}
