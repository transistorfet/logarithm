#
# Plugin Name:	polls.pm
# Description:	Question Polls Plugin
#

use Misc;
use HashFile;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	my $polls = { };
	Command->add_directory("$plugin_dir/cmds", $polls);
	Command->add_file("predict", "$plugin_dir/cmds/vote.pm", $polls);
	Command->add_file("predictions", "$plugin_dir/cmds/results.pm", $polls);
	return(0);
}

sub release_plugin {
	return(0);
}


