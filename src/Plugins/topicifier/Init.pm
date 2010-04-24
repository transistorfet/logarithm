#
# Plugin Name:	Init.pm
# Description:	Changes the topic of the channel once a week to a random topic from a list
#

package Plugins::topicifier::Init;

use strict;
use warnings;

use Timer;
use Command;
use Handler;
use Plugins::topicifier::TopicList;

my $change_day = 5;
my $change_hour = 16;

sub init_plugin {
	my ($plugin_dir) = @_;

	my $topics = Plugins::topicifier::TopicList->new();
	Timer->new(1800, 1, Handler->new("check_time", $topics));
	Command->add_directory("$plugin_dir/Commands", $topics);
	return(0);
}

sub release_plugin {
	return(0);
}

sub check_time {
	my ($topics) = @_;

	$topics->check_time($change_day, $change_hour);
}


