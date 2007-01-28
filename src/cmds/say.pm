#
# Command Name:	say.pm
#

my $module_info = {
	'help' => [
		"Usage: say [<channel>] <phrase>",
		"Description: Causes the bot to say the phrase in channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = $msg->{'args'}->[0];
	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("say_privs", 200));
	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);
	return(-1) unless ($irc->{'channels'}->in_channel($channel));

	$msg->{'phrase'} =~ s/^($channel|)\s*//;
	$irc->private_msg($channel, $msg->{'phrase'});
	return(0);
}

