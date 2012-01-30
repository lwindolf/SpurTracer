package Settings;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	settings_get
	settings_add
);

################################################################################
# Generic settings getter. Returns a representation of all settings
#
# $1	Redis handle
################################################################################
sub settings_get {
	my $redis = shift;
	my @results = ();

	foreach my $key ($redis->keys("settings!*!*")) {
		my %tmp = $redis->hgetall($key);
		push(@results, \%tmp);
	}

	return \@results;
}

################################################################################
# Generic settings setter.
#
# $1	hash of query parameters
################################################################################
sub settings_add {
	my %glob = @_;
	my $redis = Redis->new;

	return unless(defined($glob{'prefix'}) &&
	              defined($glob{'name'}));

	print STDERR "Adding setting...\n";
	foreach my $key (keys %glob) {
		print STDERR "    $key => $glob{$key}\n";
		$redis->hset("settings!$glob{prefix}!$glob{name}", $key, $glob{$key});
	}
}

1;

=head1 Settings - General Configuration Support of SpurTracer

=head2 Concept

=begin text

Settings for different groups of functionality in SpurTracer
are grouped by setting namespace prefixes. This allows Nagios
settings to coexist with alarm settings etc. A single setting
key has a hash of properties assigned which may have different
meanings for different setting namespaces.

The Setting class helps accessing single or all namespace keys
and returns them as Perl hashes or a list of hashes.

=end text

=cut
