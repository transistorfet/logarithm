#
# Command Name:	logs.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: logs [<channel>]",
		"Description: Displays the link to the channel logs for channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = $msg->{'args'}->[0];
	my $logs = $irc->{'channels'}->get_options($channel)->get_scalar_value("logs_site", "");
	if ($logs) {
		$irc->private_msg($msg->{'respond'}, $logs);
	}
	else {
		my $bot_site = $irc->{'options'}->get_scalar_value("bot_site", "");
		return(0) unless ($bot_site);
		$channel =~ s/^\#+//;
		$bot_site =~ s/(\\|\/)$//;
		$irc->private_msg($msg->{'respond'}, "$bot_site/logs.php?channel=$channel");
	}
	return(0);
}

