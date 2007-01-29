#
# Command Name:	random.pm
#

my $module_info = {
	'help' => [
		"Usage: random [<number>]",
		"Description: Displays a random number between 0 and number (100 if unspecified)"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $max = 100;
	$max = $msg->{'args'}->[1] if ($msg->{'args'}->[1]);
	$irc->private_msg($msg->{'respond'}, int(rand($max)));
	return(0);
}

