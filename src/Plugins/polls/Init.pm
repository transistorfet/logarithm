#
# Plugin Name:	Init.pm
# Description:	Question Polls Plugin
#

package Plugins::polls::Init;

use Misc;
use HashFile;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	my $polls = { };
	Command->add_directory("$plugin_dir/Commands", $polls);
	Command->add_file("predict", "$plugin_dir/Commands/vote.pm", $polls);
	Command->add_file("predictions", "$plugin_dir/Commands/results.pm", $polls);
	return(0);
}

sub release_plugin {
	return(0);
}


