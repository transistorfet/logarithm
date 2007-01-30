#
# Command Name:	fortune.pm
#

use misc;

my $module_info = {
	'help' => [
		"Usage: fortune",
		"Description: Displays a random fortune"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("fortune_privs", 1));

	foreach my $line (`fortune -a`) {
		$line = strip_return($line);
		$irc->private_msg($msg->{'respond'}, $line);
	}
	return(0);
}
