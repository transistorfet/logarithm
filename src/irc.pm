#
# Module Name:	irc.pm
# Description:	IRC Module
#

package irc;

use strict;
use IO::Socket;

use misc;
use users;
use channels;
use module;

my $options_dir = "../etc";

my $default_nick = "logarithm";
my $default_password = "";
my $default_min_tick = 0.1;
my $default_max_tick = 2;

my $irc_trys = 3;
my $irc_max_flush = 5;
my $irc_flush_delay = 2;
my $irc_max_length = 512;
my $irc_connect_timeout = 300;
my $irc_reconnect_delay = 60;

my $irc_time = get_time();

my @connections = ();

sub get_connections {
	return([ @connections ]);
}

sub new {
	my ($this, $file, $delim) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'options'} = config->new("$options_dir/options.conf");
	$self->{'nick'} = $self->{'options'}->get_scalar_value("nick", $default_nick);
	$self->{'channels'} = channels->new();
	$self->{'users'} = users->new();
	$self->{'sock'} = 0;
	$self->{'server'} = "";
	$self->{'connected'} = 0;
	$self->{'tick'} = $default_max_tick;
	$self->{'min_tick'} = $default_min_tick;
	$self->{'max_tick'} = $default_max_tick;
	$self->{'recv_queue'} = [ ];
	$self->{'send_queue'} = [ ];
	$self->{'last_flush'} = 0;
	$self->{'flush_count'} = 0;
	push(@connections, $self);
	return($self);
}

sub delete {
	my ($self) = @_;

	for my $i (0..$#connections) {
		if ($self == $connections[$i]) {
			splice(@connections, $i, 1);
			return(0);
		}
	}
	return(-1);
}

sub connect {
	my ($self) = @_;

	return(0) if ($self->{'connected'});
	return(-1) if ($self->server_connect());
	$self->identify();
	status_log("Joining Channels...");
	my @channels = $self->{'channels'}->get_channel_list();
	@channels = $self->{'options'}->get_value("channels") unless (scalar(@channels));
	foreach my $channel (@channels) {
		$self->send_msg("JOIN $channel\n");
	}
	module->evaluate_hooks("irc_connect", $self);
}

sub disconnect {
	my ($self) = @_;

	module->evaluate_hooks("irc_disconnect", $self);
	$self->flush_queue();
	my $sock = $self->{'sock'};
	print $sock "QUIT :bye\n";
	$self->{'connected'} = 0;
}

sub receive_msg {
	my ($self) = @_;

	$self->read_msgs() unless (scalar(@{ $self->{'recv_queue'} }));
	my $msg = shift(@{ $self->{'recv_queue'} });
	$self->dispatch_msg($msg);
	return($msg);
}

sub send_msg {
	my ($self, $msgtext) = @_;

	$msgtext =~ s/(\r|)\n/\r\n/;
	push(@{ $self->{'send_queue'} }, $msgtext);
	$self->flush_queue();
	my $msg = $self->parse_msg($msgtext);
	$msg->{'nick'} = $self->{'nick'};
	$msg->{'outbound'} = 1;
	push(@{ $self->{'recv_queue'} }, $msg);
}

sub change_nick {
	my ($self, $nick) = @_;

	$self->send_msg($self, "NICK $nick\n");
}

sub join_channel {
	my ($self, $channel) = @_;

	return if ($self->{'channels'}->in_channel($channel));
	$self->send_msg("JOIN $channel\n");
}

sub leave_channel {
	my ($self, $channel) = @_;

	return unless ($self->{'channels'}->in_channel($channel));
	#foreach (channel_get_option($irc->{'channels'}, $channel, "on_leave")) {
	#	push(@{ $irc->{'recv_queue'} }, irc_make_msg($irc->{'nick'}, "", "PRIVMSG", $channel, $_));
	#}
	$self->send_msg("PART $channel\n");
}

sub private_msg {
	my ($self, $channel, $text) = @_;

	$text = strip_return($text);
	$text = "Nice try! =P" if ($text =~ /^\~/);	## Don't send chanserv commands to the channel
	$self->send_msg("PRIVMSG $channel :$text\n");
}

sub action_msg {
	my ($self, $channel, $text) = @_;

	$text = strip_return($text);
	$self->send_msg("PRIVMSG $channel :\x01ACTION $text\x01\n");
}

sub notice {
	my ($self, $channel, $text) = @_;

	$text = strip_return($text);
	$self->send_msg("NOTICE $channel :$text\n");
}

sub identify {
	my ($self) = @_;

	my $password = $self->{'options'}->get_scalar_value("password", $default_password);
	$self->send_msg("NICKSERV :identify $password\n") if ($password);
}

sub set_tick {
	my ($self, $seconds) = @_;

	if (($seconds >= $self->{'min_tick'}) and ($seconds <= $self->{'max_tick'})) {
		$self->{'tick'} = $seconds;
		return(0);
	}
	return(-1);
}

sub make_msg {
	my ($self, $nick, $host, $cmd, @params) = @_;

	my $channel = lc($params[0]);
	my $respond = $channel;
	$respond = $nick unless ($channel =~ /^#/);
	return({
		'cmd' => uc($cmd),
		'outbound' => 0,
		'nick' => $nick,
		'host' => $host,
		'channel' => $channel,
		'respond' => $respond,
		'params' => [ @params ],
		'text' => $params[$#params]
	});
}

### Local Functions ###

sub server_connect {
	my ($self) = @_;

	my $sock;
	my @servers = $self->{'options'}->get_value("servers");
	while (1) {
		for my $i (0..$#servers) {
			status_log("Connecting to $servers[$i]...");
			for (1..$irc_trys) {
				$servers[$i] =~ /^(.*)(|:(.*))$/;
				my ($server, $port) = ($1, $3);
				$port = 6667 unless ($port);
				if ($sock = IO::Socket::INET->new(PeerAddr => $server, PeerPort => $port, Proto => 'tcp', Timeout => 30)) {
					$self->{'sock'} = $sock;
					$self->{'server'} = $server;
					print $sock "NICK $self->{'nick'}\n";
					print $sock "USER $self->{'nick'} 0 0 :The Bot\n";
					status_log("Connected...");
					return(0) unless ($self->init_connection());
					last;
				}
				else {
					status_log("Connection Failed:  Retrying...");
					sleep 2;
				}
			}
			status_log("Connection Failed:  Trying Next...");
		}
		sleep 1;
	}
	return(-1);
}

sub init_connection {
	my ($self) = @_;

	my $msg;
	my $time = time();
	my $sock = $self->{'sock'};
	do {
		$msg = $self->receive_msg();
		if ($msg->{'cmd'} eq "001") {
			$self->{'nick'} = $msg->{'params'}->[0];
			$self->{'connected'} = 1;
			return(0);
		}
		elsif ($msg->{'cmd'} eq "433") {
			$self->{'nick'} = "$self->{'nick'}_";
			status_log("Nick in use.  Changing to $self->{'nick'}");
			print $sock "NICK $self->{'nick'}\n";
		}
		elsif ($msg->{'cmd'} =~ /ERROR/) {
			status_log("Received error on connect ($msg->{'text'}).  Retrying in $irc_reconnect_delay seconds.");
			sleep $irc_reconnect_delay;
			return(-1);
		}
	} while (!($msg->{'cmd'} eq -1) and ((time() - $time) < $irc_connect_timeout));
	status_log("Failed to Initialize Connection");
	return(-1);
}

sub read_msgs {
	my ($self) = @_;

	$self->flush_queue();
	my ($rin, $rout, $line, $num);
	my $sock = $self->{'sock'};
	vec($rin, fileno($sock), 1) = 1;
	unless (select($rout=$rin, undef, undef, $self->{'tick'})) {
		push(@{ $self->{'recv_queue'} }, $self->make_msg("", "", "TICK"));
		return(0);
	}

	my $data = $self->{'remaining'};
	my $count = length($data);
	while (($num = select($rout=$rin, undef, undef, 0)) > 0) {
		$count = sysread($sock, $data, 1024, $count);
	}

	if ($num < 0) {
		push(@{ $self->{'recv_queue'} }, $self->make_msg("", "", "ERROR"));
		return(0);
	}

	while ($data =~ /^(.*?\r\n)(.*)$/s) {
		($line, $data) = ($1, $2);
		#print $line;
		if ($line =~ /^PING/) {
			$line =~ s/PING/PONG/i;
			print $sock "$line";
			push(@{ $self->{'recv_queue'} }, $self->make_msg("", "", "PING", $self->{'nick'}));
		}
		else {
			push(@{ $self->{'recv_queue'} }, $self->parse_msg($line));
		}
	}
	$self->{'remaining'} = $data;
	return(0);
}

sub parse_msg {
	my ($self, $line) = @_;

	my ($nick, $host, $cmd, $msg, $text, @params);
	$line = strip_return($line);
	if ($line =~ /(^:\S+ )?(\S+) (.*)$/) {
		my ($nick, $cmd, $msg) = ($1, $2, $3);
		$nick =~ s/^(:)//;
		chop($nick);
		($nick, $host) = split("!", $nick);
		if ($msg =~ /:(.*)$/) {
			$text = $1;
			$msg =~ s/( |):.*$//;
		}
		@params = split(" ", $msg);
		push(@params, $text) if ($text);
		return($self->make_msg($nick, $host, $cmd, @params));
	}
	return($self->make_msg("", "", "ERROR"));
}

sub flush_queue {
	my ($self) = @_;

	return(-1) unless ($self->{'connected'});
	if ((time() - $self->{'last_flush'}) >= $irc_flush_delay) {
		$self->{'last_flush'} = time();
		$self->{'flush_count'} = 0;
	}

	my $size = $irc_max_flush - $self->{'flush_count'};
	$size = scalar(@{ $self->{'send_queue'} }) if ($size > scalar(@{ $self->{'send_queue'} }));
	return unless ($size);

	my $sock = $self->{'sock'};
	for (1..$size) {
		print $sock shift(@{ $self->{'send_queue'} });
	}
	$self->{'flush_count'} += $size;
	return(0);
}

sub dispatch_msg {
	my ($self, $msg) = @_;

	if ($msg->{'cmd'} eq "PRIVMSG") {
		if ($msg->{'text'} =~ /^\x01PING/) {
			$self->notice($msg->{'nick'}, $msg->{'text'});
		}
	}
	elsif ($msg->{'cmd'} eq "NOTICE") {
		if ($msg->{'nick'} =~ /NickServ/i and $msg->{'text'} =~ /please identify/i) {
			$self->identify();
			status_log("-$msg->{'nick'}!$msg->{'host'}- $msg->{'text'}");
			status_log("Identifying...");
		}
		if ($self->{'connected'}) {
			status_log("-$msg->{'nick'}!$msg->{'host'}- $msg->{'text'}");
		}
	}	
	elsif ($msg->{'cmd'} eq "332") {	## TOPIC Reply
		$msg->{'channel'} = $msg->{'params'}->[1];
	}
	elsif ($msg->{'cmd'} eq "NICK") {
		foreach my $channel ($self->{'users'}->change_nick($msg->{'nick'}, $msg->{'text'})) {
			module->evaluate_hooks("irc_change_nick", $self, $msg, $channel);
		}
	}
	elsif ($msg->{'cmd'} eq "QUIT") {
		foreach my $channel ($self->{'users'}->quit($msg->{'nick'})) {
			module->evaluate_hooks("irc_quit_channel", $self, $msg, $channel);
		}
	}
	elsif ($msg->{'cmd'} eq "353") {
		$msg->{'channel'} = $msg->{'params'}->[2];
		foreach my $nick (split(" ", $msg->{'text'})) {
			$nick =~ s/^(\@|\+)//;
			$self->{'users'}->join_channel($msg->{'channel'}, $nick, $msg->{'host'});
		}
	}


	if ($msg->{'cmd'} eq "JOIN") {
		if (($msg->{'nick'} eq $self->{'nick'}) and !$msg->{'outbound'}) {	
			$self->{'channels'}->join_channel($msg->{'channel'});
		#	foreach my $command ($self->{'channels'}->get_options($msg->{'channel'})->get_value("on_join")) {
		#		push(@{ $self->{'recv_queue'} }, irc_make_msg($irc->{'nick'}, "", "PRIVMSG", $msg->{'channel'}, $command));
		#	}
		}
		$self->{'users'}->join_channel($msg->{'channel'}, $msg->{'nick'}, $msg->{'host'});
		module->evaluate_hooks("irc_dispatch_msg", $self, $msg) unless ($msg->{'outbound'});
	}
	elsif (($msg->{'cmd'} eq "PART") or ($msg->{'cmd'} eq "KICK")) {
		module->evaluate_hooks("irc_dispatch_msg", $self, $msg) unless ($msg->{'outbound'});
		my $nick = ($msg->{'cmd'} eq "KICK") ? $msg->{'params'}->[1] : $msg->{'nick'};
		$self->{'users'}->leave_channel($msg->{'channel'}, $nick);
		if (($nick eq $self->{'nick'}) and !$msg->{'outbound'}) {
			$self->{'users'}->purge_channel($msg->{'channel'});
			$self->{'channels'}->leave_channel($msg->{'channel'});
		}
	}
	else {
		module->evaluate_hooks("irc_dispatch_msg", $self, $msg);
	}
}

1;

