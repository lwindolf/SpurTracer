# Data acess object for SpurTracer

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

	# Check for mandatory fields
	unless(defined($data{host}) &&
	       defined($data{component}) &&
	       defined($data{type}) &&
	       defined($data{ctxt}) &&
	       defined($data{time})) {

		if($debug) {
			print STDERR "Invalid request:\n";
			foreach (keys(%data)) {
				print STDERR "	$_ => $data{$_}\n";
			}
		}
		return 1;
	}

	# FIXME: Validate important fields!

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
	$key .= "d".$data{time};
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
