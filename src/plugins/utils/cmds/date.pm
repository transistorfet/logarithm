#
# Command Name:	date.pm
#

my $module_info = {
	'help' => [
		"Usage: date",
		"Description: Displays the current date"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	$irc->private_msg($msg->{'respond'}, `date`);
	return(0);
}


