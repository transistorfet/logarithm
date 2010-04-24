#
# Command Name:	changetopic.pm
#

package Plugins::topicifier::Commands::changetopic;

use strict;
use warnings;

sub get_info {{
	'access' => 100,
	'help' => [
		"Usage: changetopic <topic>",
		"Description: Change the topic of the current channel to the next auto topic setter topic"
	]
}}

sub do_command {
	my ($topics, $irc, $msg, $privs) = @_;

	return(-10) if ($privs < 100);
	if ((time() - $topics->{'last'}) < $topics->MIN_WAIT_TIME) {
		$irc->notice($msg->{'nick'}, "Please wait before changing the topic again.");
		return(0);
	}
	$irc->identify();
	$topics->change_topic($irc, $msg->{'channel'});
	return(0);
}

