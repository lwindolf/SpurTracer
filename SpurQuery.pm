# Map requests to respective view

package SpurQuery;

use SpurTracerView;

# Map request names to XSLT names
my %xsltMapping = (
	"Map"			=> "Map",
	""			=> "ListAll",
	"Details"		=> "ListAllDetails",
	"Spur"			=> "Spur",
	"Announcements"		=> "ListAnnouncements",
	"Components"		=> "ComponentList",
	"Settings"		=> "Settings"
);

# Map non-obvious request names to view names
my %viewMapping = (
	""			=> "Spur",
	"Details"		=> "Spur",
	"Components"		=> "Objects"
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

	$name =~ s/^get//;

	die "No XSLT mapping for '$name'!" unless(defined($xsltMapping{$name}));

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

	my $viewName = $viewMapping{$this->{name}};
	$viewName = $this->{name} unless(defined($viewName));
	$viewName .= "View";

	require "${viewName}.pm";

	my $view = ${viewName}->new($xsltMapping{$this->{name}}, $this->{name}, %{$this->{glob}});
	$view->print();
}

1;
