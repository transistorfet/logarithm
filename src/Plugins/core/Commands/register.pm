#
# Command Name:	register.pm
#

package Plugins::core::Commands::register;

use strict;
use warnings;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: register <password>",
		"Description: Registers your nick using password"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	if ($irc->{'users'}->register($msg->{'nick'}, $msg->{'args'}->[1])) {
		$irc->notice($msg->{'nick'}, "Sorry, $msg->{'nick'} is Already Registered");
	}
	else {
		$irc->notice($msg->{'nick'}, "$msg->{'nick'} Registered Successfully");
	}
	return(0);
}

