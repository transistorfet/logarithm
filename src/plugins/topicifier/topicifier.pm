#
# Plugin Name:	topicifier.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

use misc;

my $change_day = 5;
my $change_hour = 16;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir, $irc) = @_;

	my $info = { 'changed' => 0, 'channels' => { } };
	module->register_timer("topic", 1800, 1, "check_time", $info, $irc);
	module->register_command_directory("$plugin_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}

sub check_time {
	my ($info, $irc) = @_;

	my $time = get_time();
	if (($time->{'wday'} == $change_day) and ($time->{'hour'} == $change_hour)) {
		change_topic($info, $irc) unless ($info->{'changed'});
		$info->{'changed'} = 1;
	}
	else {
		$info->{'changed'} = 0;
	}
}

sub change_topic {
	my ($info, $irc) = @_;

	status_log("Topicifier changing topics");
	$irc->identify();
	foreach my $channel ($irc->{'channels'}->get_channel_list()) {
		my $options = $irc->{'channels'}->get_options($channel);
		next unless ($options);
		next unless ($options->get_scalar_value("enable_topicifier"));
		load_topics($info, $channel) unless (defined($info->{'channels'}->{ $channel }) and scalar(@{ $info->{'channels'}->{ $channel } }));
		my $topic = shift(@{ $info->{'channels'}->{ $channel } });	
		$irc->private_msg("chanserv", "topic $channel $topic") if ($topic);
	}
}

sub load_topics {
	my ($info, $channel) = @_;

	my @topics;
	my $dir = $channel;
	$dir =~ s/^#+//;
	open(FILE, "$config_dir/$dir/topicifier.lst") or return;
	while (my $line = <FILE>) {
		push(@topics, $line) if ($line =~ /\w/);
	}
	close(FILE);
	return unless (scalar(@topics));

	my @random;
	while (scalar(@topics)) {
		my $r = int(rand(scalar(@topics)));
		push(@random, $topics[$r]);
		splice(@topics, $r, 1);
	}
	$info->{'channels'}->{ $channel } = [ @random ];
}

