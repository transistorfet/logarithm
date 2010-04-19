#
# Command Name:	delpoll.pm
#

package Plugins::polls::Commands::delpoll;

use Misc;
use HashFile;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: delpoll <name>",
		"Description: Deletes the given poll for the specified channel."
	]
}}

my $config_dir = config_dir();

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	my $poll = lc($msg->{'args'}->[1]);

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = HashFile->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my ($owner, $question, @options) = $polls->{ $channel }->get_all("${poll}_poll");
	return(-10) unless (($owner eq $msg->{'nick'}) or ($privs >= 300));
	for my $i (1..scalar(@options)) {
		$polls->{ $channel }->delete("${poll}_vote$i");
		$polls->{ $channel }->delete("${poll}_predict$i");
	}
	$polls->{ $channel }->delete("${poll}_poll");
	$polls->{ $channel }->delete("${poll}_results");
	$polls->{ $channel }->delete("${poll}_disabled");
	$polls->{ $channel }->remove("polls", $poll);
	$irc->notice($msg->{'nick'}, "Poll Removed");
	return(0);
}

