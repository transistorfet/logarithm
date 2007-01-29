#
# Command Name:	define.pm
#

my $module_info = {
	'help' => [
		"Usage: define <phrase>",
		"Description: Displays the definition for the phrase"
	]
};

my $config_dir = "../etc";

sub do_command {
	my ($defines, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);
	$msg->{'phrase'} =~ /^\s*(.+)\s*$/;
	my $word = $1;

	my $channel = ($msg->{'respond'} =~ /^\#/) ? $msg->{'respond'} : "global";
	my $file = "$config_dir/$channel/defines.lst";
	$file =~ s/\/#+/\//;
	$channel = "global" unless (-e $file);
	$defines->{ $channel } = csv->open_file($file, "\t", 1) unless (defined($defines->{ $channel }));

	my @results = $defines->{ $channel }->find_all_entries($word);
	push(@results, $defines->{'global'}->find_all_entries($word)) unless ($channel eq 'global');
	if (scalar(@results)) {
		$word = ucfirst($results[0]->[0]);
		$irc->private_msg($msg->{'respond'}, "$word:");
		for my $i (0..$#results) {
			my $num = $i + 1;
			$irc->private_msg($msg->{'respond'}, "$num. $results[$i]->[1]");
		}
	}
	else {
		$irc->private_msg($msg->{'respond'}, "$word Not Found");
	}
	return(0);
}

