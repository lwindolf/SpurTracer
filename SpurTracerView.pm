# SpurTracerView.pm: View factory with XML/XSLT serialization
#
# Copyright (C) 2012 Lars Lindner <lars.lindner@gmail.com>
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


package SpurTracerView;

use XML::Writer;

################################################################################
# Constructor
#
# $1	XLST view name
# $2	optional object type name (e.g. 'Component')
# $3	glob pattern
################################################################################
sub new {
	my $type = shift;
	my ($name, $objType, %glob) = @_;
	my $this = { };
	$this->{xslt} = $name;
	$this->{glob} = \%glob;

	if(defined($objType)) {
		$this->{objType} = $objType;
	} else {
		$this->{objType} = $name;
	}

	return bless $this, $type;
}

################################################################################
# Dump XML response on STDOUT
#
# Returns 0 on success
################################################################################
sub print {
	my $this = shift;
	my %data = %{$this->{results}};

	# FIXME: XSLT base path from package!
	unless(-f "xslt/$this->{xslt}.xsl") {
	       print "Content-type: text/html\r\n\r\n";
	       print "ERROR: Stylesheet $this->{xslt}.xsl missing!";
	       return 1;
	}

	print "Content-type: application/xml\r\n\r\n";

	my $writer = new XML::Writer(
	       OUTPUT => STDOUT,
	       DATA_MODE => 1,
	       DATA_INDENT => 3
	);
	$writer->xmlDecl('UTF-8');
	$writer->pi('xml-stylesheet', 'type="text/xsl" href="xslt/'.$this->{xslt}.'.xsl"');
	$writer->startTag('Spuren', ('now' => time()));

	# require Data::Dumper;
	# print STDERR Data::Dumper->Dump([\$this], ['data'])."\n";

	if(defined($data{'Alarms'})) {
		$writer->startTag("Alarms");
		foreach my $alarm (@{$data{'Alarms'}}) {
			$writer->emptyTag("Alarm", %$alarm);
		}
		$writer->endTag();
	}

	if(defined($data{'Settings'})) {
		$writer->startTag("Settings");
		foreach my $setting (@{$data{'Settings'}}) {
			$writer->emptyTag("Setting", %$setting);
		}
		$writer->endTag();
	}

	foreach my $key (keys %{$data{'Spuren'}}) {
		my %spur = %{$data{'Spuren'}{$key}};

		$writer->startTag("Spur", %{$spur{source}});
		foreach my $event (@{$spur{events}}) {
			$writer->emptyTag('Event', %{$event});				
		}
		$writer->endTag();
	}

	if(defined(${data{'IntervalStatistics'}})) {
		my %stats = %{$data{'IntervalStatistics'}};

		$writer->startTag("IntervalStatistics", ( 'name' => $stats{'name'} ));
		foreach my $counter (keys %stats) {
			my %values = %{$stats{$counter}};
			next if($counter eq 'name');

			$writer->startTag('Counter',  ('name' => $counter ));
			foreach my $slot (sort { $a <=> $b } keys(%values)) {
				$writer->emptyTag('Value', ( 'slot' => $slot, 'value' => $values{$slot}));
			}
			$writer->endTag();
		}
		$writer->endTag();
	}

	foreach my $tag ("Announcement", "Host", "Interface", "Component") {

		# Dump objects
		if(defined($data{$tag . 's'})) {
			$writer->startTag($tag . 's');
			foreach (@{$data{$tag .'s'}}) {
				$writer->emptyTag($tag, %{$_});
			}
			$writer->endTag();
		}

		# Dump instances
		if(defined($data{$tag . 'Instances'})) {
			$writer->startTag($tag . 'Instances');
			foreach (@{$data{$tag .'Instances'}}) {
				$writer->emptyTag('Instance', %{$_});
			}
			$writer->endTag();
		}
	}

	$writer->endTag();
	return 0;
}

1;
