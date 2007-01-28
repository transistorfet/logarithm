#
# Command Name:	bye.pm
#

my $module_info = {
	'help' => [
		"bye",
		"Causes logarithm to exit"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	if ($privs >= 500) {
		$irc->disconnect();
		exit;
	}
	return(-10);
}

