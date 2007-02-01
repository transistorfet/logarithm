#
# Command Name:	join.pm
#

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
	$irc->{'options'}->add_value("channels", $msg->{'args'}->[0]);
	$irc->join_channel($msg->{'args'}->[0]);
	return(0);
}

