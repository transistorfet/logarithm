
$module_info = {
	'help' => [
		"Usage: mod [<channel>] <nick> <level>",
		"Description: Modifies the access level for nick in channel (current if unspecified)"
	]
};

sub do_mod {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) > 3);
	my ($channel, $nick, $access) = @{ $msg->{'params'} };
	$privs = user_get_access($irc->{'users'}, $channel, $msg->{'nick'});
	return(-10) if (($privs < 350) or ($access > $privs));

	return(-1) if (user_modify_access($irc->{'users'}, $channel, $nick, $access));
	irc_notice($irc, $msg->{'nick'}, "$nick Access Modified");
	return(0);
}

