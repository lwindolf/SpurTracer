# Simple data acess object for SpurTracer

package Spuren;

use Error qw(:try);

$debug = 1;
$expiration = 3600*8;	# Expire keys after 8h

################################################################################
# Constructor
################################################################################
sub new {
	my $type = shift;
	my $this = { };

	# For now simply require a local Redis instance
	$this->{redis} = Redis->new;

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
		$value = $data{newcomponent}."::".$data{newctxt};
	}

	# Submit value
	print STDERR "Adding value >>>$key<<< = >>>$value<<<\n" if($debug);
	$this->{redis}->set($key, $value);
	$this->{redis}->expire($key, $expiration);

	if($data{type} eq "c") {
		# For context announcements
		my $akey = "announce::";
		$akey .= "n".$data{newcomponent}."::";
		$akey .= "c".$data{newctxt};
		$this->{redis}->set($akey, $key);
		$this->{redis}->expire($akey, $expiration);
		print STDERR "Adding announcement >>>$akey<<<\n" if($debug);
	} else {
		# Delete announcement on any notification
		$this->{redis}->del("announce::n$data{component}::c$data{ctxt}");
		print STDERR "Clearing announcement >>>announce::n$data{component}::c$data{ctxt}<<<\n" if($debug);
	}

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

	$filter = "d*::" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "h".$regex{host}."::*"	if(defined($regex{host}));
	$filter .= "n".$regex{component}."::*"	if(defined($regex{component}));
	$filter .= "c".$regex{ctxt}."::*"	if(defined($regex{ctxt}));
	$filter .= "t".$regex{type}."::*"	if(defined($regex{type}));
	$filter .= "s".$regex{status}		if(defined($regex{status}));

	$filter .= "*" unless(defined($regex{status}));

	print STDERR "Querying for >>>$filter<<<\n";

	my @results;
	try {
		@results = $this->{redis}->keys($filter);
	} catch Error with {
		my $ex = shift;
		print STDERR "Query failed!\n";
	}

	# Deserialize query results into a list of events
	# for (host, component, context) sets. The results will
	# be a list of such sets...
	my %results = ();
	my $i = 0;
	foreach my $key (@results) {
		next if($key =~ /skipped because its mtime/);

		# Decode value store key according to schema 
		#
		# d<time>::h<host>::n<component>::c<ctxt>::t<type>::[s<status>]
		if($key =~ /d(\d+)::h([^:]+)::n([^:]+)::c([^:]+)::t([nc])::(s(\w+))?/) {
			my $time = $1;
			my $id = $2."::".$3."::".$4;
			my $type = $5;
			my $status = $7;

			unless(defined($results{'Spuren'}{$id})) {
				next if(keys %{$results{'Spuren'}} > 100);
				$results{'Spuren'}{$id} = ();
				$i++;
			}

			# Add event to set
			my %event = ();
			$event{type} = $type;
			$event{time} = $time;
			$event{status} = $status if(defined($status));

			push(@{$results{'Spuren'}{$id}}, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}

		last if($i > 10000);
	}

	return (0, \%results);
}

################################################################################
# Generic announcement fetching method. Provides filtering as fetch_data() does.
#
# $2	Hash with Redis glob patterns. Can be empty to fetch the
#	latest n results. Otherwise it has a glob pattern for each field 
#	to be filtered. Not each fields needs to be given.
#
#	Example: Get all announced DB sync jobs
#
#		("ctxt" => "sync?", "component" => "db")
#
# Returns 	
#
# status code 			0 on success
# array of result hashes	(undefined on error)
################################################################################
sub fetch_announcements {
	my ($this, %regex, $max_results) = @_;

	# Build fetching regex
	my $filter = "announce::";
	$filter .= "n".$regex{component}."::*"	if(defined($regex{component}));

	$filter = "announce::*::" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "c".$regex{ctxt}."::*"	if(defined($regex{ctxt}));
	$filter .= "*" unless(defined($regex{ctc}));

	print STDERR "Querying for >>>$filter<<<\n";

	my @results;
	try {
		@results = $this->{redis}->keys($filter);
	} catch Error with {
		my $ex = shift;
		print STDERR "Query failed!\n";
	}

	# Deserialize query results into a list of events grouped
	# for spur (a host, component, context) sets.
	my %results = ();
	my $i = 0;
	foreach my $key (@results) {
		next if($key =~ /skipped because its mtime/);

		# Decode value store key according to schema 
		#
		# announce::n<component>::c<ctxt>
		if($key =~ /announce::n([^:]+)::c([^:]+)$/) {
			$i++;

			# Add event to set
			my %event = ();
			$event{component} = $1;
			$event{ctxt} = $2;
			# FIXME: get value

			push(@{$results{'Announcements'}}, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}

		last if($i > 100);
	}

	return (0, \%results);
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

     - newcomponent			New expected component identifier
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
