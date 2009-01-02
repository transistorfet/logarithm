#
# Command Name:	mysite.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: mysite [<name>]",
		"Description: Displays the website for the nick (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $options = $irc->{'channels'}->get_options($msg->{'args'}->[0]);
	$options = $irc->{'options'} unless ($options);
	my $website = $options->get_scalar("usersite");
	my $nick = $msg->{'args'}->[1] ? $msg->{'args'}->[1] : $msg->{'nick'};

	if ($website) {
		$irc->private_msg($msg->{'respond'}, "$website?t=users/$nick");
	}
	else {
		$irc->notice($msg->{'nick'}, "Sorry, No Website For This User");
	}
	return(0);
}

