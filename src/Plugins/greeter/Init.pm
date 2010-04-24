#
# Plugin Name:	Init.pm
# Description:	IRC Greeter
#

package Plugins::greeter::Init;

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

	if ($msg->{'cmd'} eq "JOIN") {
		my $index = "greet_" . $msg->{'nick'} . "_msg";
		my $options = $irc->{'channels'}->get_options($msg->{'respond'});
		$options = $irc->{'options'} unless ($options);
		my $greet = $options->get_scalar($index);
		$irc->private_msg($msg->{'respond'}, $greet) if ($greet);
	}
}


