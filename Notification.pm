# Serialization / Parsing / Filtering helpers for notifications

package Notification;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(notification_build_filter notification_build_key notification_build_value);

################################################################################
# Build a Redis glob expression for searching notifications
#
# $1	Hash with Redis glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
# Returns a glob pattern
################################################################################
sub notification_build_filter {
	my (%glob) = @_;

	# Build fetching glob
	my $filter = "";
	$filter .= "d".$glob{time}."::*"	if(defined($glob{time}));

	$filter = "d*::" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "h".$glob{host}."::*"	if(defined($glob{host}));
	$filter .= "n".$glob{component}."::*"	if(defined($glob{component}));
	$filter .= "c".$glob{ctxt}."::*"	if(defined($glob{ctxt}));
	$filter .= "t".$glob{type}."::*"	if(defined($glob{type}));
	$filter .= "s".$glob{status}		if(defined($glob{status}));

	$filter .= "*" unless(defined($glob{status}));

	return $filter;
}

################################################################################
# Build a notification key from a hash containing the notification properties
#
# $1	Hash with notification properties
#
# Returns a key string
################################################################################
sub notification_build_key {
	my %data = %{$_[0]};

	# Create value store key according to schema 
	#
	# d<time>::h<host>::n<component>::c<ctxt>::t<type>::[s<status>]
	my $key = "";
	$key .= "d".$data{time}."::";
	$key .= "h".$data{host}."::";
	$key .= "n".$data{component}."::";
	$key .= "c".$data{ctxt}."::";
	$key .= "t".$data{type}."::";
	$key .= "s".$data{status} if(defined($data{status}));

	return $key;
}

################################################################################
# Build a notification value from a has containing the notification properties
#
# $1	Hash with notification properties
#
# Returns a value string
################################################################################
sub notification_build_value {
	my %data = %{$_[0]};

	# Create value depending on type
	my $value = "";
	if($data{type} eq "n") {
		$value = $data{desc} if(defined($data{desc}));
	} else {
		$value = $data{newcomponent}."::".$data{newctxt};
	}

	return $value;
}

1;
