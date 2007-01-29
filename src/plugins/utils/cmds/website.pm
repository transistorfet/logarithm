#
# Command Name:	website.pm
#

my $module_info = {
	'help' => [
		"Usage: website [<channel>]",
		"Description: Displays the website for channel (current if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $options = $irc->{'channels'}->get_options($msg->{'args'}->[0]);
	$options = $irc->{'options'} unless ($options);
	my $website = $options->get_scalar_value("website");

	if ($website) {
		$irc->private_msg($msg->{'respond'}, $website);
	}
	else {
		$irc->notice($msg->{'nick'}, "Sorry, No Website For This Channel");
	}
	return(0);
}

