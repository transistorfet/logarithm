#
# Command Name:	del.pm
#

my $module_info = {
	'help' => [
		"Usage: del [<channel>] <nick>",
		"Description: Deletes the access level for nick in channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	my ($channel, $nick) = @{ $msg->{'args'} };
	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("del_privs", 400));

	return(-1) if ($irc->{'users'}->remove_access($channel, $nick));
	$irc->notice($msg->{'nick'}, "$nick Access Deleted");
	return(0);
}

