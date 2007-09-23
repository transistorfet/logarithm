#
# Command Name:	nickserv.pm
#

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: nickserv",
		"Description: Causes the bot to attempt to identify with nickserv."
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	$irc->identify();
	return(0);
}

