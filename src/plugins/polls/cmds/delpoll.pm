#
# Command Name:	delpoll.pm
#

use config;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: delpoll <name>",
		"Description: Deletes the given poll for the specified channel."
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($polls, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 2);
	my $poll = $msg->{'args'}->[1];

	return(-1) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	(my $dir = $channel) =~ s/^#+//;
	$polls->{ $channel } = config->new("$config_dir/$dir/polls.dat") unless (defined($polls->{ $channel }));

	my ($question, @options) = $polls->{ $channel }->get_value("${poll}_poll");
	for my $i (1..scalar(@options)) {
		$polls->{ $channel }->delete_value("${poll}_option$i");
	}
	$polls->{ $channel }->delete_value("${poll}_poll");
	$polls->{ $channel }->delete_value("${poll}_results");
	$polls->{ $channel }->remove_value("polls", $poll);
	$irc->notice($msg->{'nick'}, "Poll Removed");
	return(0);
}

