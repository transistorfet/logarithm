#
# Command Name:	command.pm
#

my $module_info = {
	'help' => [
		"Usage: command enable|disable <name>",
		"Description: Enables or disables the named command"
	]
};

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) != 3);
	return(-10) if ($privs < $irc->{'options'}->get_scalar_value("command_privs", 450));
	my ($channel, $cmd, $name) = @{ $msg->{'args'} };

	my $command = "cmds/$name.pm";
	return(-1) unless (-e $command);
	if ($cmd eq "enable") {
		module->register_command_module($name, $command);
		$irc->notice($msg->{'nick'}, "Command $name loaded successfully");
	}
	elsif ($cmd eq "disable") {
		module->unregister_command($name);
		$irc->notice($msg->{'nick'}, "Command $name disabled");
	}
	else {
		return(-20);
	}
	return(0);
}

