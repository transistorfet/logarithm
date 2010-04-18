#
# Command Name:	website.pm
#

package Plugins::utils::Commands::website;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: website [<channel>]",
		"Description: Displays the website for channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $options = $irc->{'channels'}->get_options($msg->{'args'}->[0]);
	$options = $irc->{'options'} unless ($options);
	my $website = $options->get_scalar("website");

	if ($website) {
		$irc->private_msg($msg->{'respond'}, $website);
	}
	else {
		$irc->notice($msg->{'nick'}, "Sorry, No Website For This Channel");
	}
	return(0);
}

