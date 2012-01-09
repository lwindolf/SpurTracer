#!/usr/bin/perl -T

# Net::Server::HTTP based SpurTracer server

use strict;
use CGI;
use Redis;
use URI::Escape;
use Error qw(:try);
use base qw(Net::Server::HTTP);
use lib ".";
use SpurQuery;
use Spuren;

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
# Data submission request handler
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

#	try {
		my $query = new SpurQuery($mode, %glob);
		$this->send_status(200);
		$query->execute();
#	} catch Error with {
#		$this->send_status(400);
#		print "Content-type: text/plain\r\n\r\n";
#		print "Invalid query";
#	}
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

	# Handle static content (currently only XSLT)
	if ($uri =~ m#^(xslt/\w+\.xsl|css/\w+\.css|js/\w+\.js)$#) {
		unless (-f $uri) {
			return $self->send_error(400, "Malformed URL");
		} else {
			$self->send_status(200);
			open(my $fh, '<', $uri) || return $self->send_501("Can't open file [$!]");
			my $type = $uri =~ /([^\.]+)$/ ? $1 : '';
			$type = $self->{'mime_types'}->{$type} || $self->{'mime_default'};
			print "Content-type: $type\r\n\r\n";
			print $_ while read $fh, $_, 8192;
			close $fh;
			return;
		}
	}

	# Handle get/set requests...
	if ($uri eq "set") {
		$self->process_data_submission ($ENV{'QUERY_STRING'});
	} elsif ($uri =~ /^(get\w*)$/) {
		$self->process_query ($ENV{'QUERY_STRING'}, $1);
	} elsif ($uri eq "getAnnouncements") {
		$self->process_query ($ENV{'QUERY_STRING'});
	} else {
		return $self->send_error (404, "$uri not found!");
	}
}
