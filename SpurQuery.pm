# Map requests to data requests and the respective view

package SpurQuery;

use Spuren;
use SpurView;
use Stats;

# Map request names to views
my %viewMapping = (
	"getMap"		=> "Map",
	"get"			=> "ListAll",
	"getDetails"		=> "ListAllDetails",
	"getSpur"		=> "Spur",
	"getAnnouncements"	=> "ListAnnouncements",
	"getComponents"		=> "ComponentList",
	"getInterfaces"		=> "InterfaceList",
	"getHosts"		=> "HostList"
);

################################################################################
# Constructor
#
# $1	query name
# $2	query fields hash
################################################################################
sub new {
	my $type = shift;
	my ($name, %glob) = @_;

	die "No such view mapping '$name'!" unless(defined($viewMapping{$name}));

	my $this = ();
	$this->{name} = $name;
	$this->{glob} = \%glob;

	return bless $this, $type;
}

################################################################################
# Run a prepared query. Print result to STDOUT
################################################################################
sub execute {
	my ($this) = @_;

	my $spuren = new Spuren();

	my ($status, %results, @tmp);
	if($this->{name} =~ /^getMap$/) {
		# Simply collect all infos about all object types...
		foreach my $type ('Host', 'Interface', 'Component') {
			$results{"${type}s"} = stats_get_object_list($spuren->{redis}, lc($type));
		}
	} elsif($this->{name} =~ /^(get|getDetails|getSpur)$/) {
		($status, $results{"Spuren"}) = $spuren->fetch_data(%{$this->{glob}});
	} elsif($this->{name} eq "getAnnouncements") {
		($status, $results{"Announcements"}) = $spuren->fetch_announcements(%{$this->{glob}});
	} elsif($this->{name} =~ /^get(Host|Interface|Component)s$/) {
		$results{"${1}s"} = stats_get_object_list($spuren->{redis}, lc($1));
	} else {
		die "This cannot happen!\n";
	}

	my $view = new SpurView($viewMapping{$this->{name}}, \%results);
	$view->print();
}

1;
