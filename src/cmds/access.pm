#
# Command Name:	access.pm
#

my $module_info = {
	'help' => [
		"Usage: access [[<channel>] <nick>]",
		"Description: Returns the access level of nick (you if unspecified) in channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) > 2);
	my $user = $msg->{'args'}->[1] ? $msg->{'args'}->[1] : $msg->{'nick'};
	my $channel = $msg->{'args'}->[0];
	my $access = $irc->{'users'}->get_access($channel, $user);
	$irc->notice($msg->{'nick'}, "Access Level of $user in $channel is $access ($msg->{'host'})");
	return(0);
}

