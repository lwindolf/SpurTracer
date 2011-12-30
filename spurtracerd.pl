#!/usr/bin/perl -w -T

# Net::Server::HTTP based SpurTracer server

use strict;
use CGI;
use Redis;
use URI::Escape;
use base qw(Net::Server::HTTP);
require "./Spuren.pm";

__PACKAGE__->run;

sub default_port { 8080 };

################################################################################
# Net::Server::HTTP initialization
#
# Set up Redis connection.
################################################################################
sub post_configure_hook {
	my $self = shift;
	my $prop = $self->{'server'};

	# For now simply require a local Redis instance
	print "Using Redis on 127.0.0.1:6379...\n";
	my $redis = Redis->new;

	# Prepare data access
	$prop->{spuren} = new Spuren($redis);
}

################################################################################
# Data submission request handler
#
# $2	HTTP URI paramaters
################################################################################
sub process_data_submission {
	my ($this, $data) = @_;

	my @data = ();
	foreach(split(/\&/, $data)) {
		push(@data, uri_unescape($_));
	}

	if($this->{server}->{spuren}->add_data(@data) == 0) {
		$this->send_status(200);
		print "Content-type: text/plain\r\n\r\n";
		print "OK";
	} else {
		$this->send_status(400);
		print "Content-type: text/plain\r\n\r\n";
		print "Invalid data";
	}
}

################################################################################
# Data submission request handler
#
# $2	HTTP URI paramaters
################################################################################
sub process_query {
	my ($this, $query) = @_;

	$this->send_status(200);
	print "Content-type: text/html\r\n\r\n";
	print "query $1\n";
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
# Distinguishes between data submission and query requests
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

	# Handle get/set requests...
	if ($uri =~ m#/set#) {
		$self->process_data_submission ($ENV{'QUERY_STRING'});
	} elsif ($uri =~ m#/get#) {
		$self->process_query ($ENV{'QUERY_STRING'});
	} else {
		return $self->send_error (404, "$uri not found!");
	}
}
