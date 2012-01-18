# Map requests to data requests and the respective view

package SpurQuery;

use Spuren;
use SpurView;
use Stats;

# Map request names to views
my %viewMapping = (
	"getMap"		=> "Map",
	"get"			=> "ListAll",
	"getDetails"		=> "ListAllDetails",
	"getSpur"		=> "Spur",
	"getAnnouncements"	=> "ListAnnouncements",
	"getComponents"		=> "ComponentList",
	"getSettings"		=> "Settings"
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

	die "No such view mapping '$name'!" unless(defined($viewMapping{$name}));

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

	my $spuren = new Spuren();

	my ($status, %results, @tmp);
	if($this->{name} =~ /^getMap$/) {
		# Simply collect all infos about all object types...
		foreach my $type ('Host', 'Interface', 'Component') {
			$results{"${type}s"}		= stats_get_object_list($spuren->{redis}, lc($type));
			$results{"${type}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($type));
		}
		foreach my $interval ('hour') {
			$results{'IntervalStatistics'}{$interval}{started}{values}	= stats_get_interval($spuren->{redis}, $interval, "object::global::started");
			$results{'IntervalStatistics'}{$interval}{failed}{values}	= stats_get_interval($spuren->{redis}, $interval, "object::global::failed");
			$results{'IntervalStatistics'}{$interval}{announced}{values}	= stats_get_interval($spuren->{redis}, $interval, "object::global::interface::announced");
			$results{'IntervalStatistics'}{$interval}{timeout}{values}	= stats_get_interval($spuren->{redis}, $interval, "object::global::interface::timeout");
		}
	} elsif($this->{name} =~ /^(get|getDetails|getSpur)$/) {
		$results{'Spuren'}		= $spuren->fetch(%{$this->{glob}});
		$results{'IntervalStatistics'}	= $spuren->fetch_statistics(%{$this->{glob}});
	} elsif($this->{name} eq "getAnnouncements") {
		$results{"Announcements"}	= $spuren->fetch_announcements(%{$this->{glob}});
	} elsif($this->{name} =~ /^get(Host|Interface|Component)s$/) {
		$results{"${1}s"}		= stats_get_object_list($spuren->{redis}, lc($1));
		$results{"${1}Instances"}	= stats_get_instance_list($spuren->{redis}, lc($1));
	} elsif($this->{name} eq "getSettings") {
		
	} else {
		die "This cannot happen!\n";
	}

	my $view = new SpurView($viewMapping{$this->{name}}, \%results);
	$view->print();
}

1;
