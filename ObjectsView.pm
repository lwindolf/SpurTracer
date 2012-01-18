# View for different object types

package ObjectsView;

use Stats;

@ISA = (SpurTracerView);

################################################################################
# Constructor
################################################################################
sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	$this->{xslt} = $this->{objType};
	$this->{objType} =~ s/s$//;

	$results{"$this->{objType}s"}		= stats_get_object_list($spuren->{redis}, lc($this->{objType}));
	$results{"$this->{objType}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($this->{objType}));

	$this->{results} = \%results;

	return bless $this, $type;
}

1;
