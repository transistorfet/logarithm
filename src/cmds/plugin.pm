#
# Command Name:	plugin.pm
#

my $module_info = {
	'help' => [
		"Usage: plugin enable|disable <name>",
		"Description: Enables or disables the named plugin"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("plugin_privs", 450));
	my ($channel, $cmd, $name) = @{ $msg->{'args'} };

	my $plugin = "plugins/$name/$name.pm";
	return(-1) unless (-e $plugin);
	if ($cmd eq "enable") {
		$irc->{'options'}->add_value("plugins", $name);
		module->load_plugin($plugin);
		$irc->notice($msg->{'nick'}, "Plugin $name loaded successfully");
	}
	elsif ($cmd eq "disable") {
		$irc->{'options'}->remove_value("plugins", $name);
		module->unload_plugin($plugin);
		$irc->notice($msg->{'nick'}, "Plugin $name disabled");
	}
	else {
		return(-20);
	}
	return(0);
}

