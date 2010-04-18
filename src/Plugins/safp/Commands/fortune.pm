#
# Command Name:	fortune.pm
#

package Plugins::safp::Commands::fortune;

use Misc;

sub get_info {{
	'access' => 1,
	'help' => [
		"Usage: fortune",
		"Description: Displays a random fortune"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	foreach my $line (`fortune -a`) {
		$line = strip_return($line);
		$irc->private_msg($msg->{'respond'}, $line);
	}
	return(0);
}
