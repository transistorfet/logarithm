#
# Plugin Name:	topicifier.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

use IRC;
use Misc;
use Timer;
use Command;
use Handler;

use plugins::topicificer::TopicList;

my $change_day = 5;
my $change_hour = 16;

my $min_wait_time = 30;

my $config_dir = config_dir();

sub init_plugin {
	my ($plugin_dir) = @_;

	my $info = { 'changed' => 0, 'last' => 0, 'channels' => { } };
	Timer->new(1800, 1, Handler->new("check_time", $info));
	#Command->add("changetopic", Handler->new("do_changetopic", $info));
	Command->add_directory("$plugin_dir/cmds", $info);
	return(0);
}

sub release_plugin {
	return(0);
}

sub check_time {
	my ($info) = @_;

	my $time = get_time();
	if (($time->{'wday'} == $change_day) and ($time->{'hour'} == $change_hour)) {
		status_log("Topicifier: Changing topics for all channels");
		my $connections = IRC::get_connections();
		foreach my $irc (@{ $connections }) {
			$irc->identify();
			foreach my $channel ($irc->{'channels'}->get_channel_list()) {
				$info->{'channels'}->{ $channel } = TopicList->new($channel) unless defined($info->{'channels'}->{ $channel });
				$info->{'channels'}->{ $channel }->change_channel_topic();
			}
		}
		$info->{'changed'} = 1;
	}
	else {
		$info->{'changed'} = 0;
	}
}







sub do_addtopic {
	my ($info, $irc, $msg, $privs) = @_;

	# TODO add the given topic
}

sub do_tagtopic {
	my ($info, $irc, $msg, $privs) = @_;

	# TODO modify the tags of a topic (either the current or by topic number)
}

sub do_topic {
	my ($info, $irc, $msg, $privs) = @_;

	# TODO get the topic and just print it to the channel
}

sub do_changetopic {
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

sub find_topic {
	my ($info, $channel, $specifier) = @_;

	load_topics($info, $channel);
	my $list = $info->{'channels'}->{ $channel };
	return($list->get($specifier)) if ($specifier =~ /^\d+$/);

	my $r = int(rand(scalar(@topics)));
	# TODO $specifier is a tag (or null), find a random one
}

sub change_topic {
	my ($info, $irc, $channel) = @_;

	my $options = $irc->{'channels'}->get_options($channel);
	return(-1) unless (defined($options) and $options->get_scalar("topicifier_enabled"));
	load_topics($info, $channel);

	# TODO something something
	my $topic = shift(@{ $info->{'channels'}->{ $channel } });	

	$irc->private_msg("chanserv", "topic $channel $topic") if ($topic);
	$info->{'last'} = time();
	return(0);
}

sub load_topics {
	my ($info, $channel) = @_;

	if (!defined($info->{'channels'}->{ $channel })) {
		status_log("Topicifier: Loading topics");
		my $dir = $channel;
		$dir =~ s/^#+//;
		$info->{'channels'}->{ $channel } = TopicList->new($channel);
	}
}

