#
# Command Name:	me.pm
#

package Plugins::core::Commands::me;

use strict;
use warnings;

sub get_info {{
	'access' => 200,
	'help' => [
		"Usage: me [<channel>] <action>",
		"Description: Causes the bot to say the action in channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = $msg->{'args'}->[0];
	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);
	return(-1) unless ($irc->{'channels'}->in_channel($channel));

	$msg->{'phrase'} =~ s/^($channel|)\s*//;
	$irc->action_msg($channel, $msg->{'phrase'});
	return(0);
}

