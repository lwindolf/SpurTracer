# SpurQuery.pm: Map Requests to Views
#
# Copyright (C) 2012 GFZ Deutsches GeoForschungsZentrum Potsdam <lars.lindner@gfz-potsdam.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package SpurQuery;

use Stats;
use SpurTracerView;

# Map request names to XSLT names
my %xsltMapping = (
	"Map"			=> "Map",
	""			=> "ListAll",
	"Details"		=> "ListAllDetails",
	"Spur"			=> "Spur",
	"Announcements"		=> "Announcements",
	"Settings"		=> "Settings"
);

# Map non-obvious request names to view names
my %viewMapping = (
	""			=> "Spur",
	"Details"		=> "Spur",
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
	$this->{'name'} = $name;
	$this->{'glob'} = \%glob;

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
