#
# Plugin Name:	defines.pm
# Description:	Word Definitions Plugin
#

use Misc;
use ListFile;

my $config_dir = "../etc";

sub init_plugin {
	my ($plugin_dir) = @_;

	unless (-e "$config_dir/defines.lst") {
		copy_file("$plugin_dir/defaults/defines.lst", "$config_dir/defines.lst");
	}

	my $defines = {
		'global' => ListFile->new("$config_dir/defines.lst", "\t", 1)
	};
	Command->add_directory("$plugin_dir/cmds", $defines);
	return(0);
}

sub release_plugin {
	return(0);
}


