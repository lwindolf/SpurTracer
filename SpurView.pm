# View for everything regarding one or more spurs

package SpurView;

use AlarmMonitor;
use Spuren;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my $stats = new Stats($this->{'glob'}{'interval'});
	my %results;

	$results{'Spuren'} = $spuren->fetch(%{$this->{glob}});
	$results{'Alarms'} = alarm_monitor_get_alarms($spuren->{redis});

	foreach	my $object (keys %{$this->{'glob'}}) {
		next unless($object =~ /^(host|component)$/);
		$results{'IntervalStatistics'} = $stats->get_interval("object!$object!$this->{glob}{$object}", ('started', 'failed'));
	}

	$this->{'results'} = \%results;

	return bless $this, $type;
}

1;
