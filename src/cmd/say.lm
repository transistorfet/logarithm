
$module_info = {
	'help' => [
		"Usage: say [<channel>] <phrase>",
		"Description: Causes the bot to say the phrase in channel (current if unspecified)"
	]
};

sub do_say {
	local($irc, $msg, $privs) = @_;

	return(-10) if (user_get_access($irc->{'users'}, $msg->{'params'}->[0], $msg->{'nick'}) < (channel_get_option($irc->{'channels'}, $msg->{'respond'}, "say_access", 200))[0]);
	return(-20) if (scalar(@{ $msg->{'params'} }) < 2);

	$msg->{'text'} =~ s/^say ($msg->{'params'}->[0]|)\s*//;
	irc_private_msg($irc, $msg->{'params'}->[0], $msg->{'text'}) if (irc_in_channel($irc, $msg->{'params'}->[0]));
	return(0);
}

