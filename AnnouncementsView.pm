# 'Announcements' view

package AnnouncementsView;

use AlarmMonitor;
use Spuren;

@ISA = (SpurTracerView);

sub new {
	my $type = shift;
	my $this = SpurTracerView->new(@_);
	my $spuren = new Spuren();
	my %results;

	$results{"Announcements"} = $spuren->fetch_announcements(%{$this->{glob}});
	$results{'Alarms'} = alarm_monitor_get_alarms($spuren->{redis});

	$this->{results} = \%results;

	return bless $this, $type;
}

1;
