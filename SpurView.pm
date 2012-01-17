# Simple XSLT based data presentation
#
# Serializes data and manages XSLT stylesheets

package SpurView;

use XML::Writer;

################################################################################
# Constructor
#
# $2	View Name (base name of XSLT style sheet without extension)
# $3	Result as provided by Spuren access object
################################################################################
sub new {

	my $type = shift;
	my $this = { };

	$this->{name} = shift;
	$this->{data} = shift;

	return bless $this, $type;
}

################################################################################
# Dump XML response on STDOUT
#
# Returns 0 on success
################################################################################
sub print {
	my ($this) = @_;

	# FIXME: XSLT base path from package!
	unless(-f "xslt/" . $this->{name} .".xsl") {
		print "Content-type: text/html\r\n\r\n";
		print "ERROR: Stylesheet missing!";
		return 1;
	}

	print "Content-type: application/xml\r\n\r\n";

	my $writer = new XML::Writer(
		OUTPUT => STDOUT,
		DATA_MODE => 1,
		DATA_INDENT => 3
	);
	$writer->xmlDecl('UTF-8');
	$writer->pi('xml-stylesheet', 'type="text/xsl" href="xslt/'.$this->{name}.'.xsl"');
	$writer->startTag('Spuren', ('now' => time()));

	my %data = %{$this->{data}};

	# require Data::Dumper;
	# print STDERR Data::Dumper->Dump([\$this], ['data'])."\n";

	foreach my $key (keys %{$data{'Spuren'}}) {

		if($key =~ /^([^:]+)::([^:]+)::([^:]+)$/) {
			my %spur = %{$data{'Spuren'}{$key}};

			$writer->startTag("Spur", %{$spur{source}});
			foreach my $event (@{$spur{events}}) {
				$writer->emptyTag('Event', %{$event});				
			}
			$writer->endTag();
		}
	}

	if(defined(${data{'IntervalStatistics'}})) {
		my %stats = %{$data{'IntervalStatistics'}};

		$writer->startTag("IntervalStatistics");
		foreach my $interval (keys %stats) {

			$writer->startTag('Interval', ( 'name' => $interval ));
			foreach my $object (keys %{$stats{$interval}}) {
				my %values = %{${stats}{$interval}{$object}{values}};

				$writer->startTag('Object',  ('type' => $object ));
				foreach my $slot (sort { $a <=> $b } keys(%values)) {
					$writer->emptyTag('Value', ( 'slot' => $slot, 'value' => $values{$slot}));
				}
				$writer->endTag();
			}
			$writer->endTag();
		}
		$writer->endTag();
	}

	foreach my $tag ("Announcement", "Host", "Interface", "Component") {
		next unless defined($data{$tag . 's'});

		# Dump objects
		$writer->startTag($tag . 's');
		foreach (@{$data{$tag .'s'}}) {
			$writer->emptyTag($tag, %{$_});
		}
		$writer->endTag();

		# Hosts and Announcements have no instances...
		next if($tag eq "Host" or $tag eq "Announcement");

		# Dump instances
		$writer->startTag($tag . 'Instances');
		foreach (@{$data{$tag .'Instances'}}) {
			$writer->emptyTag('Instance', %{$_});
		}
		$writer->endTag();

	}

	$writer->endTag();
	return 0;
}

1;
