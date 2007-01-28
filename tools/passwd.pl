#!/usr/bin/perl
#
# Script Name:	passwd.pl
# Description:	Modify the passwd file from the command line.
#

use strict;
use lib '../src';
use csv;

my $config_dir = "../etc";

if ((scalar(@ARGV) < 3) or (scalar(@ARGV) > 4)) {
	print "Usage: passwd.pl <nick> <password> [<hostmask>]\n";
}
else {
	my ($ret);
	my ($nick, $password, $hostmask) = @ARGV;
	my $passwd_file = csv->open_file("$config_dir/passwd");

	$password = crypt($password, $nick);
	my @entry = $passwd_file->find_entry($nick);
	if ($entry[0]) {
		$hostmask = $entry[2] unless ($hostmask);
		$ret = $passwd_file->replace_entry($nick, $password, $hostmask);
	}
	else {
		$ret = $passwd_file->add_entry($nick, $password, $hostmask);
	}

	if ($ret) {
		print "Error setting password for $nick\n";
	}
	else {
		print "Password for $nick set successfully\n";
	}
}

