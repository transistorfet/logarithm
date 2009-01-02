#
# Module Name:	Selector.pm
# Description:	Socket Selector
#

package Selector;

use strict;
use warnings;

use IO::Socket;
use Handler;

my %sockets = ();

sub create_socket {
	my (%opt) = @_;

	return(undef) unless defined($opt{Handler});
	$opt{Proto} = 'tcp' unless defined($opt{Proto});
	$opt{Retries} = 1 unless defined($opt{Retries});

	my $sock;
	for (1..$opt{Retries}) {
		if ($sock = IO::Socket::INET->new(%opt)) {
			Selector::add_socket($sock, $opt{Handler});
			return($sock);
		}
	}
	return(undef);
}

sub close_socket {
	my ($sock) = @_;

	Selector::remove_socket($sock);
	$sock->close();
}

sub add_socket {
	my ($sock, $handler) = @_;
	$sockets{ $sock } = { 'socket' => $sock, 'handler' => $handler };
}

sub remove_socket {
	my ($sock) = @_;
	delete($sockets{ $sock });
}

sub wait_all {
	my ($timeout) = @_;

	my ($rin, $rout) = ("", "");
	foreach my $key (keys(%sockets)) {
		vec($rin, fileno($sockets{ $key }->{ 'socket' }), 1) = 1;
	}

	my $read = select($rout=$rin, undef, undef, $timeout);
	return(-1) if ($read == -1);

	foreach my $key (keys(%sockets)) {
		if (vec($rout, fileno($sockets{ $key }->{ 'socket' }), 1)) {
			$sockets{ $key }->{'handler'}->handle($sockets{ $key }->{'socket'});
		}
	}
	return(0);
}

sub is_ready {
	my ($sock) = @_;

	my ($rin, $rout) = ("", "");
	vec($rin, fileno($sock), 1) = 1;
	return(select($rout=$rin, undef, undef, 0));
}

1;


