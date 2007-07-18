#
# Command Name:	results.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: results [<poll-name|poll-num>]",
		"Description: Displays the results for the specified poll."
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	my $poll = lc($msg->{'args'}->[1]);

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = config->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	if ($poll =~ /^\d$/) {
		my @list = $polls->{ $channel }->get_value("polls");
		($irc->notice($msg->{'nick'}, "Invalid poll number") and return(0)) if (($poll < 1) or ($poll > scalar(@list)));
		$poll = $list[$poll - 1];
	}
	my ($owner, $question, @options) = $polls->{ $channel }->get_value("${poll}_poll");
	($irc->notice($msg->{'nick'}, "Poll not found.") and return(0)) unless ($question);

	my $total = 0;
	my @results = ();
	for my $i (1..scalar(@options)) {
		my @votes = $polls->{ $channel }->get_value("${poll}_option$i");
		$total += scalar(@votes);
		push(@results, [ @votes ]);
	}

	$irc->notice($msg->{'nick'}, "Results for: $question");
	$irc->notice($msg->{'nick'}, "Total votes: $total");
	foreach my $i (0..$#options) {
		my $num = $i + 1;
		my $percent = sprintf("%.1d", (scalar(@{ $results[$i] }) / $total) * 100);
		$irc->notice($msg->{'nick'}, "    $num) $options[$i]: $percent% (@{ $results[$i] })");
	}
	my $results = $polls->{ $channel }->get_scalar_value("${poll}_results");
	$irc->notice($msg->{'nick'}, "Additional Results: $results") if ($results);
	return(0);
}

