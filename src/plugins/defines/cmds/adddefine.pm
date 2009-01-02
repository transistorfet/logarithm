#
# Command Name:	adddefine.pm
#

use ListFile;

sub get_info {{
	'access' => 50,
	'help' => [
		"Usage: adddefine <phrase>: <definition>",
		"Description: Adds the definition for phrase to the list for the specified channel"
	]
}}

my $config_dir = "../etc";

sub do_command {
	my ($defines, $irc, $msg, $privs) = @_;

	return(-20) if ((scalar(@{ $msg->{'args'} }) < 2) or !($msg->{'phrase'} =~ /:/));

	$msg->{'phrase'} =~ /\s*(.+?)\s*:\s*(.+?)\s*$/;
	my ($word, $define) = ($1, $2);
	return(-1) unless ($word);
	$word = ucfirst($word);

	my $channel = ($msg->{'respond'} =~ /^\#/) ? $msg->{'respond'} : "global";
	my $file = "$config_dir/$channel/defines.lst";
	$file =~ s/\/#+/\//;
	$defines->{ $channel } = ListFile->new($file, "\t", 1) unless (defined($defines->{ $channel }));

	$defines->{ $channel }->add($word, $define);
	$irc->notice($msg->{'nick'}, "Definition Added");
	return(0);
}

