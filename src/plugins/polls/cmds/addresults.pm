#
# Command Name:	addresults.pm
#

use config;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: addresults <name> <text>",
		"Description: Adds the given poll results for the specified channel under the given name.",
		"             The <text> will appear verbatim at the end of the poll results.",
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	$msg->{'phrase'} =~ /\s*(.+?)\s+(.+?)\s*$/;
	my ($poll, $text) = ($1, $2);
	$poll = lc($poll);
	($irc->notice($msg->{'nick'}, "Results must be less than 256 characters.") and return(0)) if (length($text) > 256);

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = config->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my ($owner, $question) = $polls->{ $channel }->get_value("${poll}_poll");
	return(-10) unless (($owner eq $msg->{'nick'}) or ($privs >= 300));
	$polls->{ $channel }->set_value("${poll}_results", $text);
	$irc->notice($msg->{'nick'}, "Poll Results Added");
	return(0);
}

