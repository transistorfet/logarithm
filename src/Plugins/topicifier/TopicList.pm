#
# Plugin Name:	TopicList.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

package Plugins::topicifier::TopicList;

use IRC;
use Misc;
use Timer;
use Command;
use Handler;

my $min_wait_time = 30;

my $config_dir = config_dir();

sub MIN_WAIT_TIME { return $min_wait_time; }

sub new {
	my ($this) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'last'} = 0;
	$self->{'changed'} = 0;
	$self->{'channels'} = { };
	return($self);
}

sub check_time {
	my ($self, $day, $hour) = @_;

	my $time = get_time();
	if (($time->{'wday'} == $day) and ($time->{'hour'} == $hour)) {
		$self->change_all_topics() unless ($info->{'changed'});
		$self->{'changed'} = 1;
	}
	else {
		$self->{'changed'} = 0;
	}
}

sub change_all_topics {
	my ($self) = @_;

	status_log("Topicifier: Changing topics");
	my $connections = IRC::get_connections();
	foreach my $irc (@{ $connections }) {
		$irc->identify();
		foreach my $channel ($irc->{'channels'}->get_channel_list()) {
			$self->change_topic($irc, $channel);
		}
	}
}

sub change_topic {
	my ($self, $irc, $channel) = @_;

	my $options = $irc->{'channels'}->get_options($channel);
	return(-1) unless ($options);
	return(-1) unless ($options->get_scalar("topicifier_enabled"));
	$self->load_topics($channel) unless (defined($self->{'channels'}->{ $channel }) and scalar(@{ $self->{'channels'}->{ $channel } }));
	my $topic = shift(@{ $self->{'channels'}->{ $channel } });	
	$irc->private_msg("chanserv", "topic $channel $topic") if ($topic);
	$self->{'last'} = time();
	return(0);
}

sub add_topic {
	my ($self, $channel, $topic) = @_;

	my $dir = $channel;
	$dir =~ s/^#+//;
	open(FILE, ">>$config_dir/$dir/topicifier.lst") or return(-1);
	print FILE "$topic\n";
	close(FILE);
	my $list = $self->{'channels'}->{ $channel };
	my $r = int(rand(scalar(@{ $list })));
	splice(@{ $list }, $r, 0, $topic);
}

sub load_topics {
	my ($self, $channel) = @_;

	status_log("Topicifier: Loading topics");
	my @topics;
	my $dir = $channel;
	$dir =~ s/^#+//;
	open(FILE, "$config_dir/$dir/topicifier.lst") or return;
	while (my $line = <FILE>) {
		chomp($line);
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
	$self->{'channels'}->{ $channel } = [ @random ];
}

