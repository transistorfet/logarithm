#
# Command Name:	access.lm
# Version:	0.1
# Package:	Users
#

$module_info = {
	'help' => [
		"Usage: access [[<channel>] <nick>]",
		"Description: Returns the access level of nick (you if unspecified) in channel (current if unspecified)"
	]
};

sub do_access {
	local($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) > 2);
	$user = $msg->{'params'}->[1] ? $msg->{'params'}->[1] : $msg->{'nick'};
	$access = user_get_access($irc->{'users'}, $msg->{'params'}->[0], $user);
	irc_notice($irc, $msg->{'nick'}, "Access Level of $user in $msg->{'params'}->[0] is $access ($msg->{'server'})");
	return(0);
}

