#
# Command Name:	date.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: date",
		"Description: Displays the current date"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	$irc->private_msg($msg->{'respond'}, `date`);
	return(0);
}


