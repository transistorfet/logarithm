#
# Command Name:	leave.lm
# Version:	0.1
# Package:	Core
#

$module_info = {
	'help' => [
		"Usage: leave <channel>",
		"Description: Causes the bot to leave the specified channel"
	]
};

sub do_leave {
	local($irc, $msg, $privs) = @_;

	return(-10) if ($privs < 475);
	return(-20) if (scalar(@{ $msg->{'params'} }) != 1);

	irc_leave_channel($irc, $msg->{'params'}->[0]);
	module_purge_channel($msg->{'params'}->[0]);
	return(0);
}

