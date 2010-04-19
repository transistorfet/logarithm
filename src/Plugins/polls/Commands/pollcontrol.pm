#
# Command Name:	pollcontrol.pm
#

package Plugins::polls::Commands::pollcontrol;

use Misc;
use HashFile;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: pollcontrol <name> (enable|disable)",
		"Description: Controls the given poll for the specified channel."
	]
}}

my $config_dir = config_dir();

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($poll, $operation) = (lc($msg->{'args'}->[1]), lc($msg->{'args'}->[2]));

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = HashFile->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my ($owner, $question, @options) = $polls->{ $channel }->get_all("${poll}_poll");
	return(-10) unless (($owner eq $msg->{'nick'}) or ($privs >= 300));

	if ($operation eq "enable") {
		$polls->{ $channel }->set("${poll}_disabled", 0);
		$irc->notice($msg->{'nick'}, "Poll Enabled");
	}
	elsif ($operation eq "disable") {
		$polls->{ $channel }->set("${poll}_disabled", 1);
		$irc->notice($msg->{'nick'}, "Poll Disabled");
	}
	else {
		return(-20);
	}
	return(0);
}

