#
# Command Name:	plugin.pm
#

package Plugins::core::Commands::plugin;

use strict;
use warnings;

sub get_info {{
	'access' => 450,
	'help' => [
		"Usage: plugin enable|disable <name>",
		"Description: Enables or disables the named plugin"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	my ($channel, $cmd, $name) = @{ $msg->{'args'} };

	if ($cmd eq "enable") {
		my $module = Module->load_plugin($name);
		if (defined($module)) {
			$irc->notice($msg->{'nick'}, "Plugin $name loaded successfully");
			$irc->{'options'}->add("plugins", $name);
		}
		else {
			$irc->notice($msg->{'nick'}, "Error: Plugin $name not found");
		}
	}
	elsif ($cmd eq "disable") {
		$irc->{'options'}->remove("plugins", $name);
		Module->release_plugin($name);
		$irc->notice($msg->{'nick'}, "Plugin $name disabled");
	}
	else {
		return(-20);
	}
	return(0);
}

