#
# Plugin Name:	TopicList.pm
# Description:	Maintains a list of topics
#

package plugins::topicifier::TopicList;

use Misc;
use ListFile;

my $config_dir = config_dir();

sub new {
	my ($this, $channel) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'channel'} = $channel;
	status_log("Topicifier: Loading topics for $channel");
	my $dir = $channel;
	$dir =~ s/^#+//;
	$self->{'topics'} = ListFile->new("$config_dir/$dir/topics.lst");
	return($self);
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
	return(-1) unless (defined($options) and $options->get_scalar("topicifier_enabled"));

	# TODO something something
	my $topic = shift(@{ $info->{'channels'}->{ $channel } });	

	$irc->private_msg("chanserv", "topic $channel $topic") if ($topic);
	$info->{'last'} = time();
	return(0);
}


1;

