#
# Command Name:	tail.pm
#

use Misc;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: tail [<channel>] [<lines>]",
		"Description: Sends the last 10 lines of the channel logs (current if unspecified) as a notice."
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my @data;
	my $time = get_time();
	return(-20) unless (scalar(@{ $msg->{'args'} }) <= 2);	
	my ($channel, $lines) = @{ $msg->{'args'} };

	$lines =~ s/^-//;
	$lines = 5 unless ($lines =~ /\d+/);
	$channel =~ s/^#+//;
	my $file = sprintf("$irc->{'logging'}->{'logdir'}/$channel/%02d-%02d-%02d.txt", $time->{'year'}, $time->{'month'}, $time->{'day'});
	open(FILE, $file) or (status_log("Cannot Open Log $file") and return(-1));
	while (my $line = <FILE>) {
		unshift(@data, $line);
	}
	close(FILE);
	foreach my $i (reverse 1..$lines) {
		$irc->notice($msg->{'nick'}, $data[$i]);
	}
	return(0);
}


