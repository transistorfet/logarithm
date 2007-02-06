#
# Plugin Name:	defines.pm
# Description:	Word Definitions Plugin
#

use csv;
use misc;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	unless (-e "$config_dir/defines.lst") {
		copy_file("$plugin_dir/defaults/defines.lst", "$config_dir/defines.lst");
	}

	my $defines = {
		'global' => csv->open_file("$config_dir/defines.lst", "\t", 1)
	};
	module->register_command_directory("$plugin_dir/cmds", $defines);
	return(0);
}

sub release_plugin {
	return(0);
}


