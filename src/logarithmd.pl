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
	my $bot = Logarithm->new();

	return($bot->loop());
}

