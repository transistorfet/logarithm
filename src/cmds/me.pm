
$module_info = {
	'help' => [
		"Usage: me [<channel>] <action>",
		"Description: Causes the bot to say the action in channel (current if unspecified)"
	]
};

sub do_me {
	local($irc, $msg, $privs) = @_;

	return(-10) if (user_get_access($irc->{'users'}, $msg->{'params'}->[0], $msg->{'nick'}) < channel_get_option($irc->{'channels'}, $msg->{'respond'}, "me_access", 200));
	return(-20) if (scalar(@{ $msg->{'params'} }) < 2);

	if (irc_in_channel($irc, $msg->{'params'}->[0])) {
		$msg->{'text'} =~ s/^me ($msg->{'params'}->[0]|)\s*//;
		irc_action_msg($irc, $msg->{'params'}->[0], "$msg->{'text'}");
	}
	return(0);
}

