
$module_info = {
	'help' => [
		"Description: Automatic topic setter which changes the topic after a certain length of time"
	]
};

my %topicifier_info = ( 'day' => 0, 'list' => [ ] );

sub init_topicifier {
	local($irc, $msg, $privs) = @_;

	my $time = get_time();
	$topicifier_info{'day'} = $time->{'wday'};
	return(-1) if (module_register_alarm("topicifier.pm", "do_topicifier_alarm", $msg->{'respond'}, 86400, $msg));
}

sub do_topicifier_alarm {
	local($irc, $msg, $privs) = @_;

	my $time = get_time();
	if ($time->{'wday'} != $topicifier_info{'day'}) {
		$topicifier_info{'day'} = $time->{'wday'};
		do_topicifier_change_topic($irc, $msg) if ($time->{'wday'} == 5);
	}
}

sub do_topicifier_change_topic {
	local($irc, $msg) = @_;

	do_load_topics($msg->{'respond'}) unless (scalar(@{ $topicifier_info{'list'} }));

	my $topic = shift(@{ $topicifier_info{'list'} });	
	irc_send_msg($irc, "PRIVMSG chanserv :topic $msg->{'respond'} $topic\n");
}

sub do_load_topics {
	local($channel) = @_;

	my @random = ();
	my @topics = csv_search($channel, "autotopics.lst", ':', undef);
	return unless (scalar(@topics));

	while (scalar(@topics)) {
		$r = int(rand(scalar(@topics)));
		push(@random, $topics[$r]->[0]);
		splice(@topics, $r, 1);
	}
	@{ $topicifier_info{'list'} } = @random;
}

