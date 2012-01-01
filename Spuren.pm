# Simple data acess object for SpurTracer

package Spuren;

$debug = 1;

################################################################################
# Constructor
#
# $2	Redis connection
################################################################################
sub new {
	my $type = shift;
	my $this = { };

	$this->{redis} = shift;

	return bless $this, $type;
}

################################################################################
# Add submitted data
#
# $2	hash with notification properties 
#	("host" => "host1", "component" => "db", ...)
#
# Returns 0 on success
################################################################################
sub add_data {
	my ($this, %data) = @_;

	if($debug) {
		print STDERR "New notification:\n";
		foreach(keys(%data)) {
			print STDERR "	$_ => $data{$_}\n";
		}
	}

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

	# Create value depending on type
	my $value = "";
	if($data{type} eq "n") {
		$value = $data{desc} if(defined($data{desc}));
	} else {
		$value = $data{newctxt};
	}

	# Submit value
	print STDERR "Adding to value store >>>$key<<< = >>>$value<<<\n" if($debug);
	$this->{redis}->set($key, $value);

	return 0;
}

################################################################################
# Generic fetching method providing filtering. We heavily rely on Redis
# key matching and hope for it to be performing well... The Redis documentation
# warns to not use the KEYS method for production, so this might not work
# on the long term.
#
# Supported patterns see: http://redis.io/commands/keys
#
# $2	Hash with Redis glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
#	Example: Get all CMS notification for all appservers
#
#		("host" => "appserver?", "component" => "cms")
#
# Returns 	
#
# status code 			0 on success
# array of result hashes	(undefined on error)
################################################################################
sub fetch_data {
	my ($this, %regex, $max_results) = @_;

	# Build fetching regex
	my $filter = "";
	$filter .= "d".$regex{time}."::*"	if(defined($regex{time}));

	$filter = "*::" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "h".$regex{host}."::*"	if(defined($regex{host}));
	$filter .= "n".$regex{component}."::*"	if(defined($regex{component}));
	$filter .= "c".$regex{ctxt}."::*"	if(defined($regex{ctxt}));
	$filter .= "t".$regex{type}."::*"	if(defined($regex{type}));
	$filter .= "*s".$regex{status}		if(defined($regex{status}));

	$filter =~ s/\*\*/*/g;	# The status pattern from above might cause 
				# double *

	print STDERR "Querying for >>>$filter<<<\n";

	my @results = $this->{redis}->keys($filter);
	my @decoded = ();
	foreach my $key (@results) {
		# Decode value store key according to schema 
		#
		# d<time>::h<host>::n<component>::c<ctxt>::t<type>::[s<status>]
		if($key =~ /d(\d+)::h(\w+)::n(\w+)::c(\w+)::t([nc])::(s(\w+))?/) {
			my %result = (
				'time'		=> $1,
				'host'		=> $2,
				'component'	=> $3,
				'ctxt'		=> $4,
				'type'		=> $5
			);
			$result{status} = $6 if(defined($6));
			push(@decoded, \%result);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}
	}

	return (0, \@decoded);
}

1;

__END__

=head1 Spuren - Data Access and Model

=head2 Notification Properties

=begin text

We trace behaviour by correlating even notifications with the following 
general properties:

- host	 				...the hosts name the notification 
					originates from (not necessarily
					fully qualified)
- component 				...producing the notification
- ctxt					Context Identifier
- time					Unix Time Stamp
- desc					Human readable description (optional)
- type 					notification/context creation

Each notification has the following type specific properties:

  For type "notification"

     - status 				running/start/finished/failed

  For type "context creation"

     - newctxt				New expected context identifier
			 		used to correlate two different 
					notification series

=end text

=head2 Redis Schema

=begin text

We layout the about notification properties in Redis as following

	Key Schema: 

		d<time>::h<host>::n<component>::c<ctxt>::t<type>::[s<status>]

	Value Schema:

		For type 'notification'

			<description>

		For type 'context creation'

			<newctxt>

The assumption is that filtering is only necessary by for the properties
listed in the key schema. Prefixing each field with a character should
allow fast matching e.g. /::ndb::/ to find all notifications for the 
"db" component.

NOTE: DON'T RELY ON THE SCHEMA IT MIGHT CHANGE AT ANY TIME!

=end text

=cut
