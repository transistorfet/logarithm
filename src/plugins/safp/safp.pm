#
# Plugin Name:	safp.pm
# Description:	Super Awesome Fun Pack!
#

my $install_dir;

sub init_plugin {
	my ($dir) = @_;

	$install_dir = $dir;
	module->register_command_directory("$install_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}


