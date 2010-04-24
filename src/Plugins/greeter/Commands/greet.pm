#
# Command Name:	greet.pm
#

package Plugins::greeter::Commands::greet;

use strict;
use warnings;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: greet <msg>",
		"Description: Sets the greet message displayed when you join the channel.  Use 'none' to disable."
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) unless ($msg->{'channel'} =~ /^\#/);
	my $options = $irc->{'channels'}->get_options($msg->{'channel'});
	return(-1) unless ($options);

	my $index = "greet_$msg->{'nick'}_msg";
	if ($msg->{'phrase'} eq "none") {
		return(-1) if ($options->set($index, ""));
		$irc->notice($msg->{'nick'}, "Greeting disabled");
	}
	else {
		return(-1) if ($options->set($index, $msg->{'phrase'}));
		$irc->notice($msg->{'nick'}, "Greeting set to $msg->{'phrase'}");
	}
}

