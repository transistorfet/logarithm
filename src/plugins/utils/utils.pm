#
# Plugin Name:	utils.pm
# Description:	General Utility Commands Plugin
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


