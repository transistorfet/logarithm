#!/usr/bin/perl
#
# Name:		logarithmd.pl
# Description:	Logarithm IRC Bot
#

use strict;
use warnings;

use POSIX 'setsid';

use Logarithm;

my $usage = "logarithmd.pl ??";
my $bot;
my $pid_file = "logarithmd.pid";

main();
exit(0);

sub main {

	my $result = process_args();
	die "Invalid Arguments.\n$usage\n" if ($result < 0);

	my $pid = fork();
	if ($pid < 0) {
		die "Error forking process.\n";
	}
	elsif ($pid > 0) {
		## Parent Process
		exit(0);
	}
	else {
		## Child Process (Daemon)
		write_pid();
		setsid();
		open(STDIN, "/dev/null") or die "Unable to open /dev/null: $!";
		open(STDOUT, ">/dev/null");
		open(STDERR, ">/dev/null");
		$SIG{TERM} = \&handle_sigterm;
		$SIG{INT} = \&handle_sigterm;
		$SIG{HUP} = \&handle_sighup;
		$bot = Logarithm->new();
		return($bot->loop());
	}
}

sub write_pid {
	open(PID, ">$pid_file") or die "Error writing pid file!\n";
	print PID "$$";
	close(PID);
}

sub process_args {
	# TODO any args
	return(0);
}

sub handle_sigterm {
	$bot->release();
	unlink($pid_file);
	exit(0);
}

sub handle_sighup {
	# TODO reload everything
}

