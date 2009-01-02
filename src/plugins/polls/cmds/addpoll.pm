#
# Command Name:	addpoll.pm
#

use HashFile;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: addpoll <name> \"<question>\" \"<option1>\" ...",
		"Description: Adds the given poll for the specified channel under the given name.",
		"             The name must contain only alphanumeric characters or the \'_\'",
		"             character and be less than 32 letters."
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	$msg->{'phrase'} =~ /\s*(.+?)\s+(.+?)\s*$/;
	my ($poll, $rest) = ($1, $2);
	return(-1) if (!$poll or !($poll =~ /^\w+$/) or ($poll =~ /^\d+$/) or (length($poll) > 32));
	$poll = lc($poll);
	$rest =~ s/^\s*\"//;
	$rest =~ s/\"\s*$//;
	my @params = split(/\"\s+\"/, $rest);
	unshift(@params, $msg->{'nick'});

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = HashFile->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my ($owner, $question) = $polls->{ $channel }->get_all("${poll}_poll");
	return(-10) unless (($owner eq $msg->{'nick'}) or ($privs >= 300));
	$polls->{ $channel }->set("${poll}_poll", @params);
	$polls->{ $channel }->add("polls", $poll);
	$irc->notice($msg->{'nick'}, "Poll Added");
	return(0);
}

