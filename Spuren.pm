# Simple data acess object for SpurTracer

package Spuren;

use locale;
use POSIX qw(strftime);
use Error qw(:try);
use Notification;
use Stats;
#use Interfaces;

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
	$this->{today} = strftime("%F", localtime());

	return bless $this, $type;
}

################################################################################
# Time formatting helper
#
# $1	Unix time stamp
#
# Returns string with formatted date
################################################################################
sub nice_time {
	my ($this, $ts) = @_;

	my $result = strftime("%F %T", localtime($ts));
	$result =~ s/^$this->{today} //;	# shorten time if possible

	return $result;
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

	my $key = notification_build_key(\%data);
	my $value = notification_build_value(\%data);

	# Submit value
	$this->{redis}->set($key, $value);
	$this->{redis}->expire($key, $expiration);

	if($data{type} eq "c") {
		# For context announcements:
		
		# Check if any notifications already exist, to avoid
		# adding announcements on races...
		my ($status, @notifications) = $this->_query_redis(
			('component' => $data{newcomponent},
			'ctxt' => $data{newctxt})
		);

		if($#notifications < 0) {
			my $akey = "announce::";
			$akey .= "n".$data{newcomponent}."::";
			$akey .= "c".$data{newctxt};
			$this->{redis}->set($akey, $key);
			$this->{redis}->expire($akey, $expiration);
			print STDERR "Adding announcement >>>$akey<<<\n" if($debug);
			stats_add_interface_announced($this->{redis}, $data{host}, $data{component}, $data{newcomponent});
		} else {
			print STDERR "Not adding announcement as interface was already triggered!\n" if($debug);
		}
	} else {
		# For normal notifications:

		# Delete announcement on any notification
		$this->{redis}->del("announce::n$data{component}::c$data{ctxt}");
	}

	# And finally the statistics
	stats_add_start_notification($this->{redis}, $data{host}, $data{component}) if($data{status} eq "started");
	stats_add_error_notification($this->{redis}, $data{host}, $data{component}) if($data{status} eq "failed");

	return 0;
}

################################################################################
# Run a query agains Redis.
#
# $2	List with filter rules as supported by notification_build_filter()
#
# Returns 	
#
# status code 			0 on success
# array of result hashes	(undefined on error)
################################################################################
sub _query_redis {
	my ($this, %glob) = @_;

	my $filter = notification_build_filter(%glob);
	#print STDERR "Querying for >>>$filter<<<\n" if($debug);

	my @results;
	try {
		@results = $this->{redis}->keys($filter);
		return (0, @results);
	} catch Error with {
		my $ex = shift;
		print STDERR "Query >>>$filter<<< failed!\n";
		return (1, undef);
	}
}

################################################################################
# Generic fetching method providing filtering. We heavily rely on Redis
# key matching and hope for it to be performing well... The Redis documentation
# warns to not use the KEYS method for production, so this might not work
# on the long term.
#
# Supported patterns see: http://redis.io/commands/keys
#
# $2	List with filter rules as supported by notification_build_filter()
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
	my ($this, %glob) = @_;
	my ($status, @keys) = $this->_query_redis(%glob);

	# Deserialize query results into a list of events
	# for (host, component, context) sets. The results will
	# be a list of such sets...
	my %results;
	my $i = 0;
	foreach my $key (@keys) {
		next if($key =~ /skipped because its mtime/);

		# Decode value store key according to schema 
		#
		# d<time>::h<host>::n<component>::c<ctxt>::t<type>::[s<status>]
		if($key =~ /d(\d+)::h([^:]+)::n([^:]+)::c([^:]+)::t([nc])::(s(\w+))?/) {
			my $time = $1;
			my $id = $2."::".$3."::".$4;
			my $type = $5;
			my $status = $7;

			unless(defined($results{$id})) {
				next if(keys %results > 100);
				$results{$id}{source}{host} = $2;
				$results{$id}{source}{component} = $3;
				$results{$id}{source}{ctxt} = $4;
				$results{$id}{source}{started} = $time;
				$results{$id}{source}{startDate} = $this->nice_time($time);
				$results{$id}{events} = ();
				$i++;
			}

			my %event = ();
			$event{type} = $type;
			$event{time} = $time;
			$event{date} = $this->nice_time($time);
			$event{status} = $status if(defined($status));
			if($type eq "n") {
				$event{desc} = $this->{redis}->get($key);
			} else {
				$this->{redis}->get($key) =~ /^(\w+)::(\w+)$/;
				$event{newctxt} = $2;
				$event{newcomponent} = $1;

				$event{status} = "announced";
				$event{status} = "finished" unless($this->{redis}->exists("announce::n".$event{newcomponent}."::c".$event{newctxt}));
			}

			# Add event to spur set
			push(@{$results{$id}{events}}, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}

		last if($i > 10000);
	}

	return ($status, \%results);
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
	my ($this, %glob, $max_results) = @_;
	my $today = strftime("%F", localtime());

	# Build fetching glob
	my $filter = "announce::";
	$filter .= "n".$glob{component}."::*"	if(defined($glob{component}));

	$filter = "announce::*::" if($filter eq "");	# Avoid starting wildcard if possible

	$filter .= "c".$glob{ctxt}."::*"	if(defined($glob{ctxt}));
	$filter .= "*" unless(defined($glob{ctc}));

	my @keys;
	try {
		@keys = $this->{redis}->keys($filter);
	} catch Error with {
		my $ex = shift;
		print STDERR "Query failed!\n";
		return (1, undef);
	}

	# Deserialize query results into a list of events grouped
	# for spur (a host, component, context) sets.
	my @results = ();
	my $i = 0;
	foreach my $key (@keys) {
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

			# Extract additional info from value
			if($this->{redis}->get($key) =~ /^d(\d+)::h(\w+)::n([^:]+)::c([^:]+)::/) {	# FIXME: Isolate parsing into Notification.pm
				$event{sourceHost} = $2;
				$event{sourceComponent} = $3;
				$event{sourceCtxt} = $4;

				$event{time} = $1;
				$event{date} = $this->nice_time($1)
			}

			push(@results, \%event);
		} else {
			print STDERR "Invalid key encoding: >>>$key<<<!\n";
		}

		last if($i > 100);
	}

	return (0, \@results);
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
