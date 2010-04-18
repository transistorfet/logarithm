#
# Command Name:	add.pm
#

package Plugins::core::Commands::add;

sub get_info {{
	'access' => 350,
	'help' => [
		"Usage: add [<channel>] <nick> <level>",
		"Description: Adds the nick to the access list of channel (current if unspecified) to level"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($channel, $nick, $access) = @{ $msg->{'args'} };
	return(-10) if ($access > $privs);
	return(-1) unless ($irc->{'channels'}->in_channel($channel));

	if ($irc->{'users'}->add_access($channel, $nick, $access)) {
		$irc->notice($msg->{'nick'}, "Nick Already Exists");
	}
	else {
		$irc->notice($msg->{'nick'}, "$nick Access Added");
	}
	return(0);
}

