#
# Plugin Name:	Init.pm
# Description:	Word Definitions Plugin
#

package Plugins::defines::Init;

use strict;
use warnings;

use Misc;
use ListFile;

my $config_dir = config_dir();

sub init_plugin {
	my ($plugin_dir) = @_;

	unless (-e "$config_dir/defines.lst") {
		copy_file("$plugin_dir/defaults/defines.lst", "$config_dir/defines.lst");
	}

	my $defines = {
		'global' => ListFile->new("$config_dir/defines.lst", "\t", 1)
	};
	Command->add_directory("$plugin_dir/Commands", $defines);
	return(0);
}

sub release_plugin {
	return(0);
}


