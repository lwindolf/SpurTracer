# View for settings tab

package SettingsView;

use Settings;
use Stats;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	foreach my $type ('Host', 'Interface', 'Component') {
		$results{"${type}s"}		= stats_get_object_list($spuren->{redis}, lc($type));
		$results{"${type}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($type));
	}
	$results{'Settings'} = settings_get_all($spuren->{redis});
	$this->{results} = \%results;

	return bless $this, $type;
}

1;
