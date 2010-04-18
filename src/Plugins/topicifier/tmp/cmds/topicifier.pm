#
# Command Name:	addtopic.pm
#

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: addtopic <topic>",
		"Description: Adds the topic to the channel topics list for the current channel's auto topic setter"
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($info, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);

	my $channel = $msg->{'args'}->[0];
	$msg->{'phrase'} =~ s/^\Q$channel\E\s*//;

	$channel =~ s/^#+//;
	open(FILE, ">>$config_dir/$channel/topicifier.lst") or return(-1);
	print FILE "$msg->{'phrase'}\n";
	close(FILE);
	$irc->notice($msg->{'nick'}, "Topic Added");
	return(0);
}

