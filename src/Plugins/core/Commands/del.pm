#
# Command Name:	del.pm
#

package Plugins::core::Commands::del;

use strict;
use warnings;

sub get_info {{
	'access' => 400,
	'help' => [
		"Usage: del [<channel>] <nick>",
		"Description: Deletes the access level for nick in channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	my ($channel, $nick) = @{ $msg->{'args'} };

	return(-1) if ($irc->{'users'}->remove_access($channel, $nick));
	$irc->notice($msg->{'nick'}, "$nick Access Deleted");
	return(0);
}

