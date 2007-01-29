#
# Command Name:	google.pm
#

my $module_info = {
	'help' => [
		"Usage: google <phrase>",
		"Description: Displays the website link for a google search for phrase"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);
	$msg->{'phrase'} =~ /^\s*(.+)\s*$/;
	my $phrase = $1;
	$phrase =~ s/ /\+/g;
	my $channel = $msg->{'respond'};
	$channel =~ s/^#//;

	my $website = "http://www.google.com/search?hl=en&q=$phrase";
	$irc->private_msg($msg->{'respond'}, $website);
	return(0);
}


