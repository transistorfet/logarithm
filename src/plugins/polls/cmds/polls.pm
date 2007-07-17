#
# Command Name:	polls.pm
#

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: polls [<poll-name|poll-num>]",
		"Description: Displays the active polls for the specified channel or the details",
		"             of a poll if the poll's name or number is given."
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = config->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my $poll = $msg->{'args'}->[1];
	if ($poll) {
		if ($poll =~ /^\d$/) {
			my @list = $polls->{ $channel }->get_value("polls");
			($irc->notice($msg->{'nick'}, "Invalid poll number") and return(0)) if ($poll >= scalar(@list));
			$poll = $list[$poll];
		}
		my ($question, @options) = $polls->{ $channel }->get_value("${poll}_poll");
		($irc->notice($msg->{'nick'}, "Poll not found.") and return(0)) unless ($question);

		$irc->private_msg($msg->{'respond'}, "$question");
		my $num = 1;
		foreach my $option (@options) {
			$irc->private_msg($msg->{'respond'}, "    $num) $option");
			$num++;
		}
	}
	else {
		my $num = 1;
		my @list = $polls->{ $channel }->get_value("polls");
		foreach my $poll (@list) {
			my $question = $polls->{ $channel }->get_scalar_value("${poll}_poll");
			$irc->private_msg($msg->{'respond'}, "$num) $question ($poll)");
			$num++;
		}
	}
	return(0);
}

