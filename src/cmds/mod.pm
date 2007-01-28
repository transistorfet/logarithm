#
# Command Name:	mod.pm
#

my $module_info = {
	'help' => [
		"Usage: mod [<channel>] <nick> <level>",
		"Description: Modifies the access level for nick in channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($channel, $nick, $access) = @{ $msg->{'args'} };
	return(-10) if (($access > $privs) or ($privs < $irc->{'options'}->get_scalar_value("mod_privs", 350)));

	return(-1) if ($irc->{'users'}->modify_access($channel, $nick, $access));
	$irc->notice($msg->{'nick'}, "$nick Access Modified");
	return(0);
}

