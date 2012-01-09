# Map requests to data requests and the respective view

package SpurQuery;

use Spuren;
use SpurView;
use Stats;

# Map request names to views
my %viewMapping = (
	"get"			=> "ListAll",
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

	my ($status, @results);
	if($this->{name} eq "get") {
		($status, @results) = $spuren->fetch_data(%{$this->{glob}});
	} elsif($this->{name} eq "getAnnouncements") {
		($status, @results) = $spuren->fetch_announcements(%{$this->{glob}});
	} elsif($this->{name} =~ "get(Host|Interface|Component)s") {
		my @hosts = stats_get_object_list($spuren->{redis}, lc($1));
		push(@results, {"${1}s" => \@hosts});
	} else {
		die "This cannot happen!\n";
	}

	my $view = new SpurView($viewMapping{$this->{name}}, @results);
	$view->print();
}

1;
