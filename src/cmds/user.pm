#
# Command Name:	user.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: user <password|hostmask> <value>",
		"Description: Changes your password of hostmask"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($channel, $cmd, $value) = @{ $msg->{'args'} };
	$cmd = lc($cmd);

	if ($cmd eq "password") {
		return(-1) if ($irc->{'users'}->change_password($msg->{'nick'}, $value));
		$irc->notice($msg->{'nick'}, "Password Changed Successfully");
	}
	elsif ($cmd eq "hostmask") {
		return(-1) if ($irc->{'users'}->change_hostmask($msg->{'nick'}, $value));
		$irc->notice($msg->{'nick'}, "Hostmask Changed Successfully");
	}
	else {
		return(-20);
	}
}

