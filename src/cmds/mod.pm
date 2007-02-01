#
# Command Name:	mod.pm
#

sub get_info {{
	'access' => 350,
	'help' => [
		"Usage: mod [<channel>] <nick> <level>",
		"Description: Modifies the access level for nick in channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($channel, $nick, $access) = @{ $msg->{'args'} };
	return(-10) if ($access > $privs);

	return(-1) if ($irc->{'users'}->modify_access($channel, $nick, $access));
	$irc->notice($msg->{'nick'}, "$nick Access Modified");
	return(0);
}

