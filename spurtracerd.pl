#!/usr/bin/perl -T

# Net::Server::HTTP based SpurTracer server

use strict;
use CGI;
use Redis;
use URI::Escape;
use base qw(Net::Server::HTTP);
require "./Spuren.pm";
require "./SpurView.pm";

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
		xsl => 'application/xslt+xml'
	};
	$self->{mime_default} = 'text/plain';
}

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

	my %data;
	foreach(split(/\&/, $data)) {
		$data{$1} = $2 if(/(\w+)=(.+)/);
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


	if($this->{server}->{spuren}->add_data(%data) == 0) {
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
################################################################################
sub process_query {
	my ($this, $query) = @_;

	my %fields = ();

	if(defined($query)) {
		# Decode filtering fields if we got some
		foreach(split(/\&/, $query)) {
			$fields{$1} = $2 if(/(\w+)=(.+)/);
		}
	}

	my ($status, @results) = $this->{server}->{spuren}->fetch_data(%fields);

	unless($status == 0) {
		$this->send_status(400);
		print "Content-type: text/plain\r\n\r\n";
		print "Invalid query";
	}

	$this->send_status(200);

	my $view = new SpurView("ListAll", @results);
	$view->print();
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
	if ($uri =~ m#^xslt/#) {
		unless (-f $uri) {
			return $self->send_error(400, "Malformed URL");
		} else {
			print STDERR "Request for file $uri...\n";

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
	} elsif ($uri eq "get") {
		$self->process_query ($ENV{'QUERY_STRING'});
	} else {
		return $self->send_error (404, "$uri not found!");
	}
}
