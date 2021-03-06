#
# Command Name:	deldefine.pm
#

package Plugins::defines::Commands::deldefine;

use strict;
use warnings;

use Misc;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: deldefine <phrase>",
		"Description: Deletes all definition of phrase in the current channel's definitions list"
	]
}}

my $config_dir = config_dir();

sub do_command {
	my ($defines, $irc, $msg, $privs) = @_;

	return(-20) if (scalar(@{ $msg->{'args'} }) < 2);

	$msg->{'phrase'} =~ /^\s*(.+?)\s*$/;
	my $word = lc($1);

	return(0) unless ($msg->{'respond'} =~ /^\#/);
	my $channel = $msg->{'respond'};
	my $file = "$config_dir/$channel/defines.lst";
	$file =~ s/\/#+/\//;
	return(0) unless (-e $file);
	$defines->{ $channel } = ListFile->new($file, "\t", 1) unless (defined($defines->{ $channel }));

	if ($defines->{ $channel }->remove($word)) {
		$irc->notice($msg->{'nick'}, "Error deleting $word");
	}
	else {
		$irc->notice($msg->{'nick'}, "$word Deleted");
	}
	return(0);
}

