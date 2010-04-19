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

sub main {
	$Logarithm::DEBUG = 1;
	my $bot = Logarithm->new();
	return($bot->loop());
}

