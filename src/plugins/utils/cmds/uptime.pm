#
# Command Name:	uptime.pm
#

my $module_info = {
	'help' => [
		"Usage: uptime",
		"Description: Displays the current uptime"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	$irc->private_msg($msg->{'respond'}, `uptime`);
	return(0);
}


