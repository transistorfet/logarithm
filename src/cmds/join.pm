
$module_info = {
	'help' => [
		"Usage: join <channel>",
		"Description: Causes the bot to join the specified channel"
	]
};

sub do_join {
	local($irc, $msg, $privs) = @_;

	return(-10) if ($privs < 450);
	return(-20) if (scalar(@{ $msg->{'params'} }) != 1);

	irc_join_channel($irc, $msg->{'params'}->[0]);
	return(0);
}

