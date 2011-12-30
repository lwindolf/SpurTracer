# Data acess object for SpurTracer

package Spuren;

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
# $2	array of keys and value (e.g. ("key1", "val1", "key2", "val2"))
#
# Returns 0 on success
################################################################################
sub add_data {
	my ($this, $data) = @_;

	return 0;
}

1;
