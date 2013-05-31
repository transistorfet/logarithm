#
# Command Name:	pic.pm
#

package Plugins::imgcache::Commands::pic;

use strict;
use warnings;

sub get_info {{
	'access' => 0,
	'help' => [
		"Usage: pic",
		"Description: Displays the link to a random picture from the cache"
	]
}}

sub do_command {
	my ($irc, $msg, $privs) = @_;

	opendir(DIR, "public_html/cache/") or return;
	my @files = readdir(DIR);
	closedir(DIR);
	@files =  grep { $_ ne "." and $_ ne ".." } @files;
	my $r = int(rand(scalar(@files)));
	my $dir = $files[$r];

	print "public_html/cache/$dir\n";
	opendir(DIR, "public_html/cache/$dir") or (print "PEE\n" and return);
	@files = readdir(DIR);
	closedir(DIR);
	@files =  grep { $_ ne "." and $_ ne ".." } @files;
	$r = int(rand(scalar(@files)));
	my $file = $files[$r];
	$file =~ s/ /%20/g;
	$irc->private_msg($msg->{'respond'}, "http://jabberwocky.ca/~logarithm/cache/$dir/$file");
	return(0);
}

