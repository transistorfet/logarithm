#
# Command Name:	join.pm
#

package Plugins::core::Commands::join;

sub get_info {{
	'access' => 450,
	'help' => [
		"Usage: join <channel>",
		"Description: Causes the bot to join the specified channel"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 1);
	$irc->{'options'}->add("channels", $msg->{'args'}->[0]);
	$irc->join_channel($msg->{'args'}->[0]);
	return(0);
}

