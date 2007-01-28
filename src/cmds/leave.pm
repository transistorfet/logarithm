#
# Command Name:	leave.pm
#

my $module_info = {
	'help' => [
		"Usage: leave <channel>",
		"Description: Causes the bot to leave the specified channel"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("leave_privs", 475));
	return(-20) if (scalar(@{ $msg->{'args'} }) != 1);
	$irc->leave_channel($msg->{'args'}->[0]);
	$irc->{'options'}->remove_value("channels", $msg->{'args'}->[0]);
	return(0);
}

