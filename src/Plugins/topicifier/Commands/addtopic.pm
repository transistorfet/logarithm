#
# Command Name:	addtopic.pm
#

package Plugins::topicifier::Commands::addtopic;

use strict;
use warnings;

sub get_info {{
	'access' => 100,
	'help' => [
		"Usage: addtopic <topic>",
		"Description: Adds the topic to the channel topics list for the current channel's auto topic setter"
	]
}}

sub do_command {
	my ($topics, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);

	my $channel = $msg->{'args'}->[0];
	$msg->{'phrase'} =~ s/^\Q$channel\E\s*//;
	$topics->add_topic($channel, $msg->{'phrase'});
	$irc->notice($msg->{'nick'}, "Topic Added");
	return(0);
}

