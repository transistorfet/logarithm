#
# Plugin Name:	Init.pm
# Description:	General Utility Commands Plugin
#

package Plugins::utils::Init;

use strict;
use warnings;

sub init_plugin {
	my ($plugin_dir) = @_;

	Command->add_directory("$plugin_dir/Commands");
	return(0);
}

sub release_plugin {
	return(0);
}


