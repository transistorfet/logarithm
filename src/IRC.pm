#
# Module Name:	IRC.pm
# Description:	IRC Module
#

package IRC;

use strict;
use warnings;
use IO::Socket;

use Misc;
use Users;
use Channels;
use HashFile;
use Module;

use Hook;
use Selector;

my $options_dir = "../etc";

my $default_nick = "logarithm";
my $default_password = "";

my $irc_tries = 3;
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
	$self->{'options'} = HashFile->new("$options_dir/options.conf");
	$self->{'nick'} = $self->{'options'}->get_scalar("nick", $default_nick);
	$self->{'channels'} = Channels->new();
	$self->{'users'} = Users->new();
	$self->{'socket'} = undef;
	$self->{'server'} = "";
	$self->{'connected'} = 0;
	$self->{'remaining'} = "";
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
	return(-1) if ($self->_server_connect());
	$self->identify();
	status_log("Joining Channels...");
	my @channels = $self->{'channels'}->get_channel_list();
	@channels = $self->{'options'}->get_all("channels") unless (scalar(@channels));
	foreach my $channel (@channels) {
		$self->send_msg("JOIN $channel\n");
	}
	Hook::do_hook("irc_connect", $self);
}

sub disconnect {
	my ($self) = @_;

	Hook::do_hook("irc_disconnect", $self);
	$self->_flush_queue();
	my $sock = $self->{'socket'};
	print $sock "QUIT :bye\n";
	$sock->close();
	$self->{'connected'} = 0;
	$self->{'socket'} = 0;
}

sub send_msg {
	my ($self, $msgtext) = @_;

	$msgtext =~ s/(\r|)\n/\r\n/;
	push(@{ $self->{'send_queue'} }, $msgtext);
	$self->_flush_queue();
	my $msg = $self->_parse_msg($msgtext);
	$msg->{'nick'} = $self->{'nick'};
	$msg->{'outbound'} = 1;
	push(@{ $self->{'recv_queue'} }, $msg);
}

sub change_nick {
	my ($self, $nick) = @_;

	$self->send_msg("NICK $nick\n");
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

	my $password = $self->{'options'}->get_scalar("password", $default_password);
	$self->send_msg("NICKSERV :identify $password\n") if ($password);
}

sub make_msg {
	my ($self, $nick, $host, $cmd, @params) = @_;

	my $channel = lc($params[0]);
	my $respond = $channel;
	$respond = $nick unless ($channel =~ /^#/);
	return({
		'cmd' => uc($cmd),
		'outbound' => 0,
		'nick' => defined($nick) ? $nick : "",
		'host' => defined($host) ? $host : "",
		'channel' => $channel,
		'respond' => $respond,
		'params' => [ @params ],
		'text' => $params[$#params]
	});
}

### Local Functions ###

sub _server_connect {
	my ($self) = @_;

	my $sock;
	my @servers = $self->{'options'}->get_all("servers");
	while (1) {
		for my $i (0..$#servers) {
			status_log("Connecting to $servers[$i]...");
			$servers[$i] =~ /^(.*)(|:(.*))$/;
			my ($server, $port) = ($1, $3);
			$port = 6667 unless ($port);
			if ($sock = Selector::create_socket(PeerAddr => $server, PeerPort => $port, Timeout => 30, Retries => $irc_tries, Handler => Handler->new("_handle_socket", $self))) {
				$self->{'socket'} = $sock;
				$self->{'server'} = $server;
				print $sock "NICK $self->{'nick'}\n";
				print $sock "USER $self->{'nick'} 0 0 :The Bot\n";
				status_log("Connected...");
				return(0);
			}
			else {
				status_log("Connection Failed:  Retrying...");
				sleep 2;
			}
			status_log("Connection Failed:  Trying Next...");
		}
		sleep 1;
	}
	return(-1);
}

sub _handle_socket {
	my ($self, $sock) = @_;

	$self->_read_msgs();
	while (@{ $self->{'recv_queue'} }) {
		my $msg = shift(@{ $self->{'recv_queue'} });
		$self->_dispatch_msg($msg);
	}
}

sub _read_msgs {
	my ($self) = @_;

	# TODO should this be here? how should this work?
	$self->_flush_queue();

	my $sock = $self->{'socket'};
	my $data = $self->{'remaining'};
	my $count = length($data);
	my $num;
	while (($num = Selector::is_ready($sock)) > 0) {
		$count = sysread($sock, $data, 1024, $count);
	}

	if ($num < 0) {
		push(@{ $self->{'recv_queue'} }, $self->make_msg("", "", "ERROR", "Error reading from socket"));
		return(0);
	}

	my $line;
	while ($data =~ /^(.*?\r\n)(.*)$/s) {
		($line, $data) = ($1, $2);
		#print $line;
		if ($line =~ /^PING/) {
			$line =~ s/PING/PONG/i;
			print $sock "$line";
			push(@{ $self->{'recv_queue'} }, $self->make_msg("", "", "PING", $self->{'nick'}));
		}
		else {
			push(@{ $self->{'recv_queue'} }, $self->_parse_msg($line));
		}
	}
	$self->{'remaining'} = $data;
	return(0);
}

sub _parse_msg {
	my ($self, $line) = @_;

	my ($nick, $host, $cmd, $msg, $text, @params);
	$line = strip_return($line);
	if ($line =~ /(^:\S+ )?(\S+) (.*)$/) {
		my ($nick, $cmd, $msg) = ($1, $2, $3);
		if ($nick) {
			$nick =~ s/^(:)//;
			chop($nick);
			($nick, $host) = split("!", $nick);
		}
		if ($msg =~ /:(.*)$/) {
			$text = $1;
			$msg =~ s/( |):.*$//;
		}
		@params = split(" ", $msg);
		push(@params, $text) if ($text);
		return($self->make_msg($nick, $host, $cmd, @params));
	}
	return($self->make_msg("", "", "ERROR", "Error parsing message"));
}

sub _flush_queue {
	my ($self) = @_;

	return(-1) unless ($self->{'connected'});
	if ((time() - $self->{'last_flush'}) >= $irc_flush_delay) {
		$self->{'last_flush'} = time();
		$self->{'flush_count'} = 0;
	}

	my $size = $irc_max_flush - $self->{'flush_count'};
	$size = scalar(@{ $self->{'send_queue'} }) if ($size > scalar(@{ $self->{'send_queue'} }));
	return unless ($size);

	my $sock = $self->{'socket'};
	for (1..$size) {
		print $sock shift(@{ $self->{'send_queue'} });
	}
	$self->{'flush_count'} += $size;
	return(0);
}

sub _dispatch_msg {
	my ($self, $msg) = @_;

	if ($msg->{'cmd'} eq "001") {
		$self->{'nick'} = $msg->{'params'}->[0];
		$self->{'connected'} = 1;
	}
	elsif ($msg->{'cmd'} eq "433") {
		$self->{'nick'} .= "_";
		status_log("Nick in use.  Changing to $self->{'nick'}");
		my $sock = $self->{'socket'};
		print $sock "NICK $self->{'nick'}\n";
	}
	elsif ($msg->{'cmd'} =~ /ERROR/) {
		status_log("Received error ($msg->{'text'}).");
	}
	elsif ($msg->{'cmd'} eq "PRIVMSG") {
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
			Hook::do_hook("irc_change_nick", $self, $msg, $channel);
		}
	}
	elsif ($msg->{'cmd'} eq "QUIT") {
		foreach my $channel ($self->{'users'}->quit($msg->{'nick'})) {
			Hook::do_hook("irc_quit_channel", $self, $msg, $channel);
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
		#	foreach my $command ($self->{'channels'}->get_options($msg->{'channel'})->get_all("on_join")) {
		#		push(@{ $self->{'recv_queue'} }, irc_make_msg($irc->{'nick'}, "", "PRIVMSG", $msg->{'channel'}, $command));
		#	}
		}
		$self->{'users'}->join_channel($msg->{'channel'}, $msg->{'nick'}, $msg->{'host'});
		Hook::do_hook("irc_dispatch_msg", $self, $msg) unless ($msg->{'outbound'});
	}
	elsif (($msg->{'cmd'} eq "PART") or ($msg->{'cmd'} eq "KICK")) {
		Hook::do_hook("irc_dispatch_msg", $self, $msg) unless ($msg->{'outbound'});
		my $nick = ($msg->{'cmd'} eq "KICK") ? $msg->{'params'}->[1] : $msg->{'nick'};
		$self->{'users'}->leave_channel($msg->{'channel'}, $nick);
		if (($nick eq $self->{'nick'}) and !$msg->{'outbound'}) {
			$self->{'users'}->purge_channel($msg->{'channel'});
			$self->{'channels'}->leave_channel($msg->{'channel'});
		}
	}
	else {
		## Only dispatch here when the message is not a join, part, or kick message
		Hook::do_hook("irc_dispatch_msg", $self, $msg);
	}
}

1;

