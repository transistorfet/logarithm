#
# Command Name:	add.lm
# Version:	0.1
# Package:	Users
#

$module_info = {
	'help' => [
		"Usage: add [<channel>] <nick> <level>",
		"Description: Adds the nick to the access list of channel (current if unspecified) to level"
	]
};

sub do_add {
	local($irc, $msg, $privs) = @_;
	local($channel, $nick, $access);

	return(-20) if (scalar(@{ $msg->{'params'} }) > 3);
	return(-1) unless (irc_in_channel($irc, $msg->{'params'}->[0]));
	my ($channel, $nick, $access) = @{ $msg->{'params'} };
	$privs = user_get_access($irc->{'users'}, $channel, $msg->{'nick'});
	return(-10) if (($privs < 350) or ($access > $privs));

	if (user_add_access($irc->{'users'}, $channel, $nick, $access)) {
		irc_notice($irc, $msg->{'nick'}, "Nick Already Exists");
	}
	else {
		irc_notice($irc, $msg->{'nick'}, "$nick Access Added");
	}
	return(0);
}

