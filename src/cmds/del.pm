
$module_info = {
	'help' => [
		"Usage: del [<channel>] <nick>",
		"Description: Deletes the access level for nick in channel (current if unspecified)"
	]
};

sub do_del {
	local($irc, $msg, $privs) = @_;
	local($channel, $nick);

	return(-20) if (scalar(@{ $msg->{'params'} }) > 3);
	my ($channel, $nick, $access) = @{ $msg->{'params'} };
	$privs = user_get_access($irc->{'users'}, $channel, $msg->{'nick'});
	return(-10) if (($privs < 350) or ($access > $privs));

	return(-1) if (user_remove_access($irc->{'users'}, $channel, $nick));
	irc_notice($irc, $msg->{'nick'}, "$nick Access Deleted");
	return(0);
}

