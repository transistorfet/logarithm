#
# Command Name:	uptime.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: uptime",
		"Description: Displays the current uptime"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	$irc->private_msg($msg->{'respond'}, `uptime`);
	return(0);
}


