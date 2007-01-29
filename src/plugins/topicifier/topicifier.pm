#
# Plugin Name:	topicifier.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

use misc;

my $config_dir = "../etc";

my $install_dir;
my $info = { 'changed' => 0, 'channels' => { } };

sub init_plugin {
	my ($dir, $irc) = @_;

	$install_dir = $dir;
	module->register_timer("topic", 1800, 1, "check_time", $irc);
	module->register_command_directory("$install_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}

sub check_time {
	my ($irc) = @_;

	my $time = get_time();
	if (!$info->{'changed'} and ($time->{'wday'} == 5) and ($time->{'hour'} == 16)) {
		$info->{'changed'} = 1;
		change_topic($irc);
	}
	else {
		$info->{'changed'} = 0;
	}
}

sub change_topic {
	my ($irc) = @_;

	$irc->identify();
	foreach my $channel ($irc->{'channels'}->get_channel_list()) {
		load_topics($channel) unless (scalar(@{ $info->{'channels'}->{ $channel } }));
		my $topic = shift(@{ $info->{'channels'}->{ $channel } });	
		$irc->private_msg("chanserv", "topic $channel $topic");
	}
}

sub load_topics {
	my ($channel) = @_;

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

