#
# Plugin Name:	polls.pm
# Description:	Question Polls Plugin
#

use misc;
use config;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	my $polls = { };
	module->register_command_directory("$plugin_dir/cmds", $polls);
	module->register_command_module("predict", "$plugin_dir/cmds/vote.pm", $polls);
	module->register_command_module("predictions", "$plugin_dir/cmds/results.pm", $polls);
	return(0);
}

sub release_plugin {
	return(0);
}


