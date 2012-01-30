# 'System Map' view

package MapView;

use Stats;
use AlarmMonitor;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my $stats = new Stats($this->{'interval'});
	my %results;

	# Simply collect all infos about all object types...
	foreach my $type ('Host', 'Interface', 'Component') {
		$results{"${type}s"}		= stats_get_object_list($spuren->{redis}, lc($type));
		$results{"${type}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($type));
	}

	$results{'IntervalStatistics'} = $stats->get_interval("object!global", ("started", "failed", "announced", "timeout"));
	$results{'Alarms'} = alarm_monitor_get_alarms($spuren->{redis});

	$this->{'results'} = \%results;

	return bless $this, $type;
}

1;
