#
# Plugin Name:	topicifier.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

use irc;
use misc;

my $change_day = 5;
my $change_hour = 16;

my $min_wait_time = 30;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	my $info = { 'changed' => 0, 'last' => 0, 'channels' => { } };
	module->register_timer("topic", 1800, 1, "check_time", $info);
	module->register_command("changetopic", "changetopic_command", $info);
	module->register_command_directory("$plugin_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}

sub changetopic_command {
	my ($info, $irc, $msg, $privs) = @_;

	return(-10) if ($privs < 100);
	if ((time() - $info->{'last'}) < $min_wait_time) {
		$irc->notice($msg->{'nick'}, "Please wait before changing the topic again.");
		return(0);
	}
	$irc->identify();
	change_topic($info, $irc, $msg->{'channel'});
	return(0);
}

sub check_time {
	my ($info) = @_;

	my $time = get_time();
	if (($time->{'wday'} == $change_day) and ($time->{'hour'} == $change_hour)) {
		change_all_topics($info) unless ($info->{'changed'});
		$info->{'changed'} = 1;
	}
	else {
		$info->{'changed'} = 0;
	}
}

sub change_all_topics {
	my ($info) = @_;

	status_log("Topicifier: Changing topics");
	my $connections = irc->get_connections();
	foreach my $irc (@{ $connections }) {
		$irc->identify();
		foreach my $channel ($irc->{'channels'}->get_channel_list()) {
			change_topic($info, $irc, $channel);
		}
	}
}

sub change_topic {
	my ($info, $irc, $channel) = @_;

	my $options = $irc->{'channels'}->get_options($channel);
	return(-1) unless ($options);
	return(-1) unless ($options->get_scalar_value("enable_topicifier"));
	load_topics($info, $channel) unless (defined($info->{'channels'}->{ $channel }) and scalar(@{ $info->{'channels'}->{ $channel } }));
	my $topic = shift(@{ $info->{'channels'}->{ $channel } });	
	$irc->private_msg("chanserv", "topic $channel $topic") if ($topic);
	$info->{'last'} = time();
	return(0);
}

sub load_topics {
	my ($info, $channel) = @_;

	status_log("Topicifier: Loading topics");
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

