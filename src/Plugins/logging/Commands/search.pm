#
# Command Name:	search.pm
#

package Plugins::logging::Commands::search;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: search <phrase>",
		"Description: Displays the website link for a logs search for phrase"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'params'} }) < 2);
	my $bot_site = $irc->{'options'}->get_scalar("bot_site", "");
	return(0) unless ($bot_site);

	$msg->{'phrase'} =~ /^\s*(.+)\s*$/;
	my $phrase = $1;
	$phrase =~ s/ /\+/g;
	my $channel = $msg->{'respond'};
	$channel =~ s/^\#+//;
	$bot_site =~ s/(\\|\/)$//;
	$irc->private_msg($msg->{'respond'}, "$bot_site/search.php?channel=$channel&q=$phrase");

	return(0);
}

