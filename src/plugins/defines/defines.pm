#
# Plugin Name:	defines.pm
# Description:	Word Definitions Plugin
#

use csv;
use misc;

my $install_dir;
my $config_dir = "../etc";
my $defines = { };

sub init_plugin {
	my ($dir) = @_;

	$install_dir = $dir;
	unless (-e "$config_dir/defines.lst") {
		copy_file("$install_dir/defaults/defines.lst", "$config_dir/defines.lst");
	}
	$defines->{'global'} = csv->open_file("$config_dir/defines.lst", "\t", 1);
	module->register_command_directory("$install_dir/cmds", $defines);
	return(0);
}

sub release_plugin {
	return(0);
}


