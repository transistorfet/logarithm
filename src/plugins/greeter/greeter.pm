#
# Plugin Name:	greeter.pm
# Description:	IRC Greeter
#

my $install_dir;

sub init_plugin {
	my ($dir) = @_;

	$install_dir = $dir;
	module->register_hook("greet", "irc_dispatch_msg", "hook_dispatch_msg");
	module->register_command_directory("$install_dir/cmds");
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
		my $greet = $options->get_scalar_value($index);
		$irc->private_msg($msg->{'respond'}, $greet) if ($greet);
	}
}