# 'System Map' view

package MapView;

use Stats;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	# Simply collect all infos about all object types...
	foreach my $type ('Host', 'Interface', 'Component') {
		$results{"${type}s"}		= stats_get_object_list($spuren->{redis}, lc($type));
		$results{"${type}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($type));
	}
	foreach my $interval ('hour') {
		$results{'IntervalStatistics'}{$interval}{started}{values}	= stats_get_interval($spuren->{redis}, $interval, "object!global!started");
		$results{'IntervalStatistics'}{$interval}{failed}{values}	= stats_get_interval($spuren->{redis}, $interval, "object!global!failed");
		$results{'IntervalStatistics'}{$interval}{announced}{values}	= stats_get_interval($spuren->{redis}, $interval, "object!global!interface!announced");
		$results{'IntervalStatistics'}{$interval}{timeout}{values}	= stats_get_interval($spuren->{redis}, $interval, "object!global!interface!timeout");
	}

	$this->{results} = \%results;

	return bless $this, $type;
}

1;
