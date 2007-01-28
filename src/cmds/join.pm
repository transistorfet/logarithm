#
# Command Name:	join.pm
#

my $module_info = {
	'help' => [
		"Usage: join <channel>",
		"Description: Causes the bot to join the specified channel"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("join_privs", 450));
	return(-20) if (scalar(@{ $msg->{'args'} }) != 1);
	$irc->{'options'}->add_value("channels", $msg->{'args'}->[0]);
	$irc->join_channel($msg->{'args'}->[0]);
	return(0);
}

