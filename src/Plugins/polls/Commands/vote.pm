#
# Command Name:	vote.pm
#

package Plugins::polls::Commands::vote;

use strict;
use warnings;

use Misc;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: (vote|predict) [<poll-name|poll-num>] <option>",
		"Description: Registers your vote or prediction for the given poll"
	]
}}

my $config_dir = config_dir();

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	my $type = $msg->{'command'};
	return(-1) unless (($type eq "vote") or ($type eq "predict"));

	$msg->{'phrase'} =~ /\s*(.+?)\s+(.+?)\s*$/;
	my ($poll, $vote) = ($1, $2);
	$poll = lc($poll);
	return(-20) unless ($poll and $vote);

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = HashFile->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	if ($poll =~ /^\d$/) {
		my @list = $polls->{ $channel }->get_all("polls");
		($irc->notice($msg->{'nick'}, "Invalid poll number") and return(0)) if (($poll < 1) or ($poll > scalar(@list)));
		$poll = $list[$poll - 1];
	}

	($irc->notice($msg->{'nick'}, "That poll has closed.") and return(0)) if ($polls->{ $channel }->get_scalar("${poll}_disabled"));

	my ($owner, $question, @options) = $polls->{ $channel }->get_all("${poll}_poll");
	($irc->notice($msg->{'nick'}, "Poll not found.") and return(0)) unless ($question);
	if ($vote =~ /^\d+$/) {
		($irc->notice($msg->{'nick'}, "Invalid option") and return(0)) unless (($vote >= 1) and ($vote <= scalar(@options)));
	}
	else {
		my $option = $vote;
		$vote = 0;
		foreach my $i (0..$#options) {
			if ($options[$i] =~ /\Q$option\E/i) {
				$vote = $i + 1;
				last;
			}
		}
		($irc->notice($msg->{'nick'}, "Option not found") and return(0)) unless ($vote);
	}

	for my $i (1..scalar(@options)) {
		$polls->{ $channel }->remove("${poll}_$type$i", $msg->{'nick'});
	}
	$polls->{ $channel }->add("${poll}_$type$vote", $msg->{'nick'});
	$irc->notice($msg->{'nick'}, "Vote registered for option $vote");
	return(0);
}

