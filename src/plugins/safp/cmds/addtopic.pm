#
# Command Name:	addtopic.pm
#

my $module_info = {
	'help' => [
		"Usage: addtopic [<category>:]<topic>",
		"Description: Adds the topic to the topics list for the current channel under the category if specified"
	]
};

my $config_dir = "../etc/";

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("addtopic_privs", 50));
	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);

	return(0) unless ($msg->{'args'}->[0] =~ /^#/);
	(my $dir = lc($msg->{'args'}->[0])) =~ s/^#+//;
	my $topic;
	if ($msg->{'phrase'} =~ /^\s*(.*?)\s*:\s*(.*?)\s*$/) {
		$topic = "$1:$2";
	}
	else {
		$topic = ":$msg->{'phrase'}";
	}
	open(FILE, ">>$config_dir/$dir/topics.lst") or return(-1);
	print FILE "$topic\n";
	close(FILE);

	$irc->notice($msg->{'nick'}, "Topic Added");
	return(0);
}

