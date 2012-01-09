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
	$writer->startTag('Spuren');

	my %data = %{$this->{data}};

	# require Data::Dumper;
	# print STDERR Data::Dumper->Dump([\%data], ['data'])."\n";

	foreach my $key (keys %{$data{'Spuren'}}) {
		if($key =~ /^([^:]+)::([^:]+)::([^:]+)$/) {
			$writer->startTag("Spur", 'host' => $1, 'component' => $2, 'ctxt' => $3, 'started' => ${$data{'Spuren'}{$key}}[0]->{time});
			foreach my $event (@{$data{'Spuren'}{$key}}) {
				$writer->emptyTag('Event', %{$event});				
			}
			$writer->endTag();
		}
	}

	foreach my $tag (("Announcement", "Host", "Interface", "Component")) {
		next unless defined($data{$tag . 's'});

		$writer->startTag($tag . 's');
		foreach (@{$data{$tag .'s'}}) {
			$writer->emptyTag($tag, %{$_});
		}
		$writer->endTag();
	}

	$writer->endTag();
	return 0;
}

1;
