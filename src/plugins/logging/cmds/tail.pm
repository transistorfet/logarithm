#
# Command Name:	tail.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: tail [-<lines>] [<channel>]",
		"Description: Sends the last 10 lines of the channel logs (current if unspecified) as a notice."
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my @data;
	my $time = get_time();
	my $channel = $msg->{'args'}->[0];

	$channel =~ s/^#+//;
	my $file = sprintf("$irc->{'logging'}->{'logdir'}/$channel/%02d-%02d-%02d.txt", $time->{'year'}, $time->{'month'}, $time->{'day'});
	open(FILE, "$file") or (status_log("Cannot Open Log $file") and return(-1));
	while (my $data = <FILE>) {
		unshift(@lines, $data);
	}
	close(FILE);
	for (1..5) {
		$irc->notice($msg->{'nick'}, shift(@data));
	}
	return(0);
}


