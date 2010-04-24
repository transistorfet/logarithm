#
# Plugin Name:	Init.pm
# Description:	Super Awesome Fun Pack!
#

package Plugins::safp::Init;

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


