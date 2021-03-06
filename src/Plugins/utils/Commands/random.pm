#
# Command Name:	random.pm
#

package Plugins::utils::Commands::random;

use strict;
use warnings;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: random [<number>]",
		"Description: Displays a random number between 1 and number (100 if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $max = 100;
	$max = $msg->{'args'}->[1] if ($msg->{'args'}->[1]);
	my $number = int(rand($max)) + 1;
	$irc->private_msg($msg->{'respond'}, $number);
	return(0);
}


