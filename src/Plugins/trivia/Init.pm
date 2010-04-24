#
# Plugin Name:	Init.pm
# Description:	A game that tests the players on their vocabulary
#

package Plugins::trivia::Init;

use strict;
use warnings;

use Plugins::trivia::Game;

sub get_info {{
	'access' => 100,
	'help' => [
		"Usage: trivia on|off [<category>]",
		"Description: Activates the trivia game which runs for a sequence of 20 questions or until !trivia stop is said"
	]
}}

my $default_game_length = 20;

sub init_plugin {
	my ($plugin_dir) = @_;

	my $trivia = { 'plugin_dir' => $plugin_dir };
	Command->add("trivia", Handler->new("do_trivia_command", $trivia));
	return(0);
}

sub release_plugin {
	return(0);
}

sub do_trivia_command {
	my ($trivia, $irc, $msg, $privs) = @_;

	if ($msg->{'args'}->[1] eq "on") {
		if (defined($trivia->{ $msg->{'respond'} }) and $trivia->{ $msg->{'respond'} }->is_running) {
			$irc->notice($msg->{'nick'}, "A game is already started.");
		}
		else {
			my ($name, $reverse) = (lc($msg->{'args'}->[2]), 0);
			($name, $reverse) = (lc($msg->{'args'}->[3]), 1) if ($name eq "reverse");
			$trivia->{ $msg->{'respond'} } = Plugins::trivia::Game->new($irc, $msg->{'respond'}, "$trivia->{'plugin_dir'}/lists", $name, $reverse, $default_game_length);
		}
	}
	elsif ($msg->{'args'}->[1] eq "off") {
		if (defined($trivia->{ $msg->{'respond'} })) {
			$trivia->{ $msg->{'respond'} }->release();
			delete($trivia->{ $msg->{'respond'} });
		}
		else {
			$irc->notice($msg->{'nick'}, "No game is currently running.");
		}
	}
	else {
		return(-20);
	}
	return(0);
}


