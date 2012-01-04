# Map requests to data requests and the respective view

package SpurQuery;

use Spuren;
use SpurView;

# Map request names to views
my %viewMapping = (
	"get"			=> "ListAll",
	"getAnnouncements"	=> "ListAnnouncements"
);

################################################################################
# Constructor
#
# $1	query name
# $2	query fields hash
################################################################################
sub new {
	my $type = shift;
	my ($name, %fields) = @_;

	die "No such view mapping '$name'!" unless(defined($viewMapping{$name}));

	my $this = ();
	$this->{name} = $name;

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
		($status, @results) = $spuren->fetch_data(%fields);
	} elsif($this->{name} eq "getAnnouncements") {
		($status, @results) = $spuren->fetch_announcements(%fields);
	} else {
		die "This cannot happen!\n";
	}

	my $view = new SpurView($viewMapping{$this->{name}}, @results);
	$view->print();
}

1;
