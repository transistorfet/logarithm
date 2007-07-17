#
# Command Name:	vote.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: vote [<poll-name|poll-num>] <option>",
		"Description: Registers your vote for the given poll"
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my $poll = $msg->{'args'}->[1];
	my $vote = $msg->{'args'}->[2];

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = config->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	if ($poll =~ /^\d$/) {
		my @list = $polls->{ $channel }->get_value("polls");
		($irc->notice($msg->{'nick'}, "Invalid poll number") and return(0)) if ($poll >= scalar(@list));
		$poll = $list[$poll];
	}
	my ($question, @options) = $polls->{ $channel }->get_value("${poll}_poll");
	($irc->notice($msg->{'nick'}, "Poll not found.") and return(0)) unless ($question);
	($irc->notice($msg->{'nick'}, "Invalid vote") and return(0)) unless (($vote =~ /^\d+$/) and ($vote <= scalar(@options)));

	for my $i (1..scalar(@options)) {
		$polls->{ $channel }->remove_value("${poll}_option$i", $msg->{'nick'});
	}
	$polls->{ $channel }->add_value("${poll}_option$vote", $msg->{'nick'});
	$irc->notice($msg->{'nick'}, "Vote registered for option $vote");
	return(0);
}

