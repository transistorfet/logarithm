
$module_info = {
	'help' => [
		"Description: Controls the automatic-join greeter which displays greet_msg (or wb if not defined) when someone joins the channel"
	]
};

sub init_greet {
	local($irc, $msg, $privs) = @_;

	return(-1) if (module_register_chat("greet.pm", "do_greet_chat", $msg->{'respond'}, "JOIN"));
}

sub do_greet_chat {
	local($irc, $msg, $privs) = @_;

	$greet = (channel_get_option($irc->{'channels'}, $msg->{'respond'}, "greet_" . $msg->{'nick'} . "_msg", ""))[0];
	irc_private_msg($irc, $msg->{'respond'}, $greet) if ($greet);
}
