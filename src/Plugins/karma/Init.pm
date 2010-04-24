#
# Plugin Name:	Init.pm
# Description:	Ranking System Plugin
#

package Plugins::karma::Init;

use strict;
use warnings;

sub init_plugin {
	my ($plugin_dir) = @_;

	Hook->new("irc_dispatch_msg", Handler->new("hook_dispatch_msg"));
	Command->add_directory("$plugin_dir/Commands");
	return(0);
}

sub release_plugin {
	return(0);
}


sub hook_dispatch_msg {
	my ($irc, $msg) = @_;

	if ($msg->{'cmd'} eq "PRIVMSG") {
		if ($irc->{'channels'}->in_channel($msg->{'channel'})) {
			my $text = ($msg->{'text'} =~ /^\x01ACTION (.*)\x01$/) ? $1 : $msg->{'text'};
			if ($text =~ /^(\w+)(++|--)$/) {
				# TODO record this event
			}
		}
	}
}

