#
# Command Name:	decide.pm
#

package Plugins::safp::Commands::decide;

use strict;
use warnings;

use Misc;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: decide <option> or <option> [or ...]",
		"Description: Randomly selects an option from a number of options"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);
	my $list = $msg->{'phrase'};
	$list =~ s/\s*(.*)\s*(|\r)\n$/$1/;
	return if ($list =~ /^$/);

	my @options = split(/\s+or\s+/, $list);
	my $number = int(rand(scalar(@options)));
	$irc->private_msg($msg->{'respond'}, "$options[$number]");
}

