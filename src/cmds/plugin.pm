#
# Command Name:	plugin.pm
#

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

	my $plugin_dir = "plugins/$name";
	my $plugin = "$plugin_dir/$name.pm";
	return(-1) unless (-e $plugin);
	if ($cmd eq "enable") {
		$irc->{'options'}->add("plugins", $name);
		my $module = Module->load($plugin);
		$module->call("init_plugin", $plugin_dir);
		$irc->notice($msg->{'nick'}, "Plugin $name loaded successfully");
	}
	elsif ($cmd eq "disable") {
		$irc->{'options'}->remove("plugins", $name);
		my $module = Module::get_module($plugin);
		$module->call("release_plugin");
		$module->release();
		$irc->notice($msg->{'nick'}, "Plugin $name disabled");
	}
	else {
		return(-20);
	}
	return(0);
}

