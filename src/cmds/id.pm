#
# Command Name:	id.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: id <password>",
		"Description: Identifies yourself using the given password"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	if ($irc->{'users'}->login($msg->{'nick'}, $msg->{'args'}->[1])) {
		$irc->notice($msg->{'nick'}, "Sorry, Invalid Password For $msg->{'nick'}");
	}
	else {
		$irc->notice($msg->{'nick'}, "$msg->{'nick'} Identified");
	}
	return(0);
}

