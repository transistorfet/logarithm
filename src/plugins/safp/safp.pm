#
# Plugin Name:	safp.pm
# Description:	Super Awesome Fun Pack!
#

sub init_plugin {
	my ($plugin_dir) = @_;

	Command->add_directory("$plugin_dir/cmds");
	return(0);
}

sub release_plugin {
	return(0);
}


