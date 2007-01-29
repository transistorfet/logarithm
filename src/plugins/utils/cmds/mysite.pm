#
# Command Name:	mysite.pm
#

my $module_info = {
	'help' => [
		"Usage: mysite [<name>]",
		"Description: Displays the website for the nick (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $options = $irc->{'channels'}->get_options($msg->{'args'}->[0]);
	$options = $irc->{'options'} unless ($options);
	my $website = $options->get_scalar_value("usersite");

	if ($website) {
		$irc->private_msg($msg->{'respond'}, "$website?t=users/$msg->{'nick'}");
	}
	else {
		$irc->notice($msg->{'nick'}, "Sorry, No Website For This User");
	}
	return(0);
}

