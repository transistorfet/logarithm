#!/usr/bin/perl
#
# Name:		logarithmd.pl
# Description:	Logarithm IRC Bot
#

use strict;
use warnings;

use Logarithm;

main();
exit(0);

my $bot;

sub main {
	$SIG{TERM} = \&handle_sigterm;
	$SIG{INT} = \&handle_sigterm;
	$Logarithm::DEBUG = 1;
	$bot = Logarithm->new();
	return($bot->loop());
}

sub handle_sigterm {
	$bot->release();
	exit(0);
}

