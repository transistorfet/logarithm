#
# Plugin Name:	Init.pm
# Description:	Core Commands Plugin
#

package Plugins::core::Init;

sub init_plugin {
	my ($plugin_dir) = @_;

	Command->add_directory("$plugin_dir/Commands");
	return(0);
}

sub release_plugin {
	return(0);
}

