# View for everything regarding one or more spurs

package SpurView;

use AlarmMonitor;
use Spuren;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	$results{'Spuren'}		= $spuren->fetch(%{$this->{glob}});
	$results{'IntervalStatistics'}	= $spuren->fetch_statistics(%{$this->{glob}});
	$results{'Alarms'}		= alarm_monitor_get_alarms($spuren->{redis});

	$this->{results} = \%results;

	return bless $this, $type;
}

1;
