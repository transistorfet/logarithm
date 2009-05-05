#
# Command Name:	polls.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: polls [<poll-name|poll-num>]",
		"Description: Displays the active polls for the specified channel or the details",
		"             of a poll if the poll's name or number is given.  See also: vote,",
		"             results, predict, predictions, addpoll, delpoll, addresults,",
		"             pollcontrol."
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = HashFile->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my $poll = lc($msg->{'args'}->[1]);
	if ($poll) {
		if ($poll =~ /^\d$/) {
			my @list = $polls->{ $channel }->get_all("polls");
			($irc->notice($msg->{'nick'}, "Invalid poll number") and return(0)) if (($poll < 1) or ($poll > scalar(@list)));
			$poll = $list[$poll - 1];
		}
		my ($owner, $question, @options) = $polls->{ $channel }->get_all("${poll}_poll");
		($irc->notice($msg->{'nick'}, "Poll not found.") and return(0)) unless ($question);

		$irc->notice($msg->{'nick'}, "$question");
		my $num = 1;
		foreach my $option (@options) {
			$irc->notice($msg->{'nick'}, "    $num) $option");
			$num++;
		}
	}
	else {
		my $num = 1;
		my @list = $polls->{ $channel }->get_all("polls");
		foreach my $poll (@list) {
			my $disabled = $polls->{ $channel }->get_scalar("${poll}_disabled");
			my ($owner, $question) = $polls->{ $channel }->get_all("${poll}_poll");
			$disabled = $disabled ? " (disabled)" : "";
			$irc->notice($msg->{'nick'}, "$num) $question ($poll)" . $disabled);
			$num++;
		}
	}
	return(0);
}

