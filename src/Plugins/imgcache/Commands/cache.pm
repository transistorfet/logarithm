#
# Command Name:	cache.pm
#

package Plugins::imgcache::Commands::cache;

use strict;
use warnings;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: cache [<channel>]",
		"Description: Displays the link to the image cache for the channel (current if unspecified)"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	my $channel = $msg->{'args'}->[0];
	my $cache = $irc->{'channels'}->get_options($channel)->get_scalar("cache_site", "");
	if ($cache) {
		$irc->private_msg($msg->{'respond'}, $cache);
	}
	else {
		my $bot_site = $irc->{'options'}->get_scalar("bot_site", "");
		return(0) unless ($bot_site);
		$bot_site =~ s/(\\|\/)$//;
		$irc->private_msg($msg->{'respond'}, "$bot_site/cache/");
	}
	return(0);
}

