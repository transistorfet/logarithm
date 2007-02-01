#
# Command Name:	leave.pm
#

sub get_info {{
	'access' => 475,
	'help' => [
		"Usage: leave <channel>",
		"Description: Causes the bot to leave the specified channel"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 1);
	$irc->leave_channel($msg->{'args'}->[0]);
	$irc->{'options'}->remove_value("channels", $msg->{'args'}->[0]);
	return(0);
}

