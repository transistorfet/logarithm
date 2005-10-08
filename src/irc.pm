#
# Module Name:	irc.pm
# Version:	0.6
# Description:	IRC Module
#

package irc;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(
	irc_create
	irc_connect
	irc_disconnect
	irc_get_msg
	irc_send_msg
	irc_add_server
	irc_change_nick
	irc_change_password
	irc_in_channel
	irc_join_channel
	irc_leave_channel
	irc_private_msg
	irc_action_msg
	irc_notice
	irc_identify
	irc_log
	irc_set_logging
	irc_set_log_directory
	irc_set_echo
	irc_set_tick
);


### IRC.PM START ###

use IO::Socket;
use misc;
use users;
use channels;

my $default_nick = "logarithm";
my $default_password = "";
my $default_logdir = "../logs";
my $default_min_tick = 0.1;
my $default_max_tick = 0.5;

my $irc_trys = 3;
my $irc_max_flush = 5;
my $irc_flush_delay = 1;
my $irc_max_length = 512;

my $irc_time = get_time();

sub irc_create {
	return({
		'nick' => $default_nick,
		'password' => $default_password,
		'connected' => 0,
		'sock' => 0,
		'echo' => 1,
		'tick' => $default_max_tick,
		'min_tick' => $default_min_tick,
		'max_tick' => $default_max_tick,
		'logdir' => $default_logdir,
		'log_enable' => 0,
		'users' => user_create(),
		'channels' => channel_create(),
		'servers' => [ ],
		'get_queue' => [ ],
		'send_queue' => [ ],
		'last_flush' => 0,
		'flush_count' => 0,
	});
}

sub irc_connect {
	local($irc) = @_;
	return if ($irc->{'connected'});

	return(-1) if (irc_server_connect($irc));
	irc_identify($irc);
	status_log("Joining Channels...");
	foreach (channel_list($irc->{'channels'})) {
		irc_send_msg($irc, "JOIN $_\n");
	}
	status_log("Starting Logs...");
	foreach (channel_list($irc->{'channels'})) {
		irc_start_logs($irc, $_);
	}
}

sub irc_disconnect {
	local($irc) = @_;
	foreach (channel_list($irc->{'channels'})) {
		irc_end_logs($irc, $_);
	}
	irc_flush_queue($irc);
	my $sock = $irc->{'sock'};
	print $sock "QUIT :bye\n";
	$irc->{'connected'} = 0;
}

sub irc_get_msg {
	local($irc) = @_;
	if (scalar(@{ $irc->{'get_queue'} })) {
		return(shift(@{ $irc->{'get_queue'} }));
	}
	else {
		return(irc_read_msg($irc));
	}
}

sub irc_send_msg {
	local($irc, $msg) = @_;
	push(@{ $irc->{'send_queue'} }, $msg);
	irc_flush_queue($irc);
}

sub irc_add_server {
	local($irc, $serv) = @_;

	foreach (@{ $irc->{'servers'} }) {
		return(1) if ($serv eq $_);
	}
	push(@{ $irc->{'servers'} }, $serv);
	return(0);
}

sub irc_change_nick {
	local($irc, $nick) = @_;
	$irc->{'nick'} = $nick;
	irc_send_msg($irc, "NICK $nick\n");
}

sub irc_change_password {
	local($irc, $password) = @_;
	$irc->{'password'} = $password;
	irc_identify($irc);
}

sub irc_in_channel {
	local($irc, $channel) = @_;
	return(channel_in_channel($irc->{'channels'}, $channel));
}

sub irc_join_channel {
	local($irc, $channel) = @_;
	return if (irc_in_channel($irc, $channel));
	irc_send_msg($irc, "JOIN $channel\n");
	channel_join($irc->{'channels'}, $channel);
	irc_start_logs($irc, $channel);
}

sub irc_leave_channel {
	local($irc, $channel) = @_;

	return unless (defined($irc->{'channels'}->{$channel}));
	foreach (channel_get_option($irc->{'channels'}, $channel, "on_leave")) {
		push(@{ $irc->{'get_queue'} }, irc_parse_msg($irc, $irc->{'nick'}, "", "PRIVMSG", $channel, $_));
	}
	irc_send_msg($irc, "PART $channel\n");
	channel_leave($irc->{'channels'}, $channel);
	irc_end_logs($irc, $channel);
	user_purge_channel($irc->{'users'}, $channel);
}

sub irc_private_msg {
	local($irc, $channel, $msg) = @_;

	$msg =~ s/(\r|)\n$//;
	irc_send_msg($irc, "PRIVMSG $channel :$msg\n");
	irc_log($irc, $channel, "<$irc->{'nick'}> $msg");
}

sub irc_action_msg {
	local($irc, $channel, $msg) = @_;

	$msg =~ s/(\r|)\n$//;
	irc_send_msg($irc, "PRIVMSG $channel :\x01ACTION $msg\x01\n");
	irc_log($irc, $channel, "* $irc->{'nick'} $msg");
}

sub irc_notice {
	local($irc, $channel, $msg) = @_;

	$msg =~ s/(\r|)\n$//;
	irc_send_msg($irc, "NOTICE $channel :$msg\n");
}

sub irc_identify {
	local($irc) = @_;

	irc_send_msg($irc, "NICKSERV :identify $irc->{'password'}\n") if ($irc->{'password'});
}

sub irc_log {
	local($irc, $channel, $msg) = @_;
	return unless ($channel =~ /^#/);

	my $time = get_time();
	$msg = strip_colour($msg);
	return if (irc_open_logs($irc, $channel, $irc_time));
	printf FILE ("%02d:%02d:%02d ", $time->{'hour'}, $time->{'min'}, $time->{'sec'});
	print FILE "$msg\n";
	print "$channel:$msg\n" if ($irc->{'echo'});
	irc_close_logs();
}

sub irc_set_logging {
	($irc, $channel, $value) = @_;

	if ($channel) {
		return(channel_set_option($irc->{'channels'}, $channel, "log_enable", $value));
	}
	else {
		$irc->{'log_enable'} = $value;
	}
	return(0);
}

sub irc_set_log_directory {
	local($irc, $value) = @_;
	$value =~ s/\/$//;
	$irc->{'logdir'} = $value;
	mkdir($value) unless (-e $value);
}

sub irc_set_echo {
	local($irc, $value) = @_;
	$irc->{'echo'} = $value;
}

sub irc_set_tick {
	local($irc, $value) = @_;
	if (($value >= $irc->{'min_tick'}) and ($value <= $irc->{'max_tick'})) {
		$irc->{'tick'} = $value;
		return(0);
	}
	return(-1);
}

### LOCAL SUBS ###

sub irc_server_connect {
	local($irc) = @_;
	for (my $i = 0; ; $i++) {
		for $i (0..$#{ $irc->{'servers'} }) {
			status_log("Connecting to $irc->{'servers'}->[$i]...");
			for (1..$irc_trys) {
				if ($sock = IO::Socket::INET->new(PeerAddr => $irc->{'servers'}->[$i], PeerPort => 6667, Proto => 'tcp')) {
					$irc->{'sock'} = $sock;
					print $sock "NICK $irc->{'nick'}\n";
					print $sock "USER $irc->{'nick'} 0 0 :The Bot\n";
					status_log("Connected...");
					return(0) unless (irc_init_connection($irc));
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

sub irc_init_connection {
	local($irc) = @_;
	do {
		$msg = irc_get_msg($irc);
		if ($msg->{'cmd'} eq "INIT") {
			$irc->{'connected'} = 1;
			return(0);
		}
	} while (!($msg->{'cmd'} eq -1));
	status_log("Failed to Initialize");
	return(-1);
}

sub irc_read_msg {
	local($irc) = @_;
	my $nick, $serv, $cmd, $msg, $text = ("", "", "", "", "");

	irc_check_all_logs($irc);
	irc_flush_queue($irc);
	$sock = $irc->{'sock'};
	vec($rin, fileno($sock), 1) = 1;
	if ($irc->{'connected'}) {
		return({ 'cmd' => "TICK" }) if (!($num = select($rin, undef, undef, $irc->{'tick'})));
	}
	return({ 'cmd' => "ERROR" }) if (!($line = <$sock>) || ($line =~ /^ERROR/));

	#print $line;
	if ($line =~ /^PING/) {
		$line =~ s/PING/PONG/;
		print $sock "$line";
		return({ 'cmd' => "PING", 'nick' => "", 'server' => "", 'channel' => $irc->{'nick'}, 'respond' => $irc->{'nick'}, 'msg' => "", 'text' => "" });
	}
	else {
		$line = strip_return($line);
		if ($line =~ /(^:\S+ )?(\S+) (.*)$/) {
			my ($nick, $cmd, $msg) = ($1, $2, $3);
			$nick =~ s/^(:)//;
			chop($nick);
			($nick, $serv) = split("!", $nick);
			if ($msg =~ /:(.*)$/) {
				$text = $1;
				$msg =~ s/( |):.*$//;
			}

			if ($text =~ /^\x01PING/) {
				print $sock "NOTICE $nick :$text\n";
				return({ 'cmd' => "PING", 'nick' => $nick, 'server' => $serv, 'channel' => $irc->{'nick'}, 'respond' => $nick, 'msg' => [ split(" ", $msg), $text ], 'text' => $text });
			}
			elsif ($cmd =~ /(376|422)/i) {
				return({ 'cmd' => "INIT", 'nick' => $nick, 'server' => $serv, 'channel' => $irc->{'nick'}, 'respond' => $nick, 'msg' => [ split(" ", $msg), $text ], 'text' => $text });
			}
			else {
				return(irc_parse_msg($irc, $nick, $serv, uc($cmd), $msg, $text));
			}
		}
		return({ 'cmd' => 'ERROR' });
	}
}

sub irc_flush_queue {
	local($irc) = @_;

	return(-1) unless ($irc->{'connected'});

	if ((time() - $irc->{'last_flush'}) >= $irc_flush_delay) {
		$irc->{'last_flush'} = time();
		$irc->{'flush_count'} = 0;
	}

	my $size = $irc_max_flush - $irc->{'flush_count'};
	$size = scalar(@{ $irc->{'send_queue'} }) if ($size > scalar(@{ $irc->{'send_queue'} }));
	return unless ($size);

	my $sock = $irc->{'sock'};
	for (1..$size) {
		print $sock shift(@{ $irc->{'send_queue'} });
	}
	$irc->{'flush_count'} += $size;
	return(0);
}

sub irc_parse_msg {
	local($irc, $nick, $serv, $cmd, $msg, $text) = @_;

	my @params = split(" ", $msg);
	my $channel = $params[0];
	if ($cmd eq "PRIVMSG") {
		if (irc_in_channel($irc, $channel)) {
			if ($text =~ /^\x01ACTION (.*)\x01$/) {
				irc_log($irc, $channel, "* $nick $1");
			}
			else {
				irc_log($irc, $channel, "<$nick> $text");
			}
		}
	}
	elsif ($cmd eq "NOTICE") {
		if ($nick =~ /NickServ/i and $text =~ /please identify/) {
			irc_identify($irc);
			status_log("-$nick!$server- $text");
			status_log("Identifying...");
		}
		if ($irc->{'connected'}) {
			status_log("-$nick!$server- $text");
		}
	}	
	elsif ($cmd eq "NICK") {
		foreach (user_changenick($irc->{'users'}, $nick, $text)) {
			irc_log($irc, $_, "--- nick: $nick -> $text");
		}
	}
	elsif ($cmd eq "QUIT") {
		foreach (user_quit($irc->{'users'}, $nick)) {
			irc_log($irc, $_, "--- quit: $nick ($text)");
		}
	}
	elsif ($cmd eq "TOPIC" or $cmd eq "332") {
		if ($channel eq $irc->{'nick'}) {
			$channel = $params[1];
		}
		irc_log($irc, $channel, "--- topic: ($channel) $text");
	}
	elsif ($cmd eq "JOIN") {
		$channel = $text;
		user_join($irc->{'users'}, $channel, $nick, $server);
		irc_log($irc, $channel, "--- join: $nick ($serv) $channel");
		if ($nick eq $irc->{'nick'}) {	
			foreach (channel_get_option($irc->{'channels'}, $channel, "on_join")) {
				push(@{ $irc->{'get_queue'} }, irc_parse_msg($irc, $irc->{'nick'}, "", "PRIVMSG", $channel, $_));
			}
		}
	}
	elsif ($cmd eq "PART") {
		user_leave($irc->{'users'}, $channel, $nick);
		irc_log($irc, $channel, "--- part: $nick ($text) $channel");
	}
	elsif ($cmd eq "NAMES" or $cmd eq "353") {
		$channel = @params[2];
		irc_log($irc, $channel, "--- names: $channel ($text)");
		foreach (split(" ", $text)) {
			s/^(\@|\+)//;
			user_join($irc->{'users'}, $channel, $_, $server) unless ($_ eq $irc->{'nick'});
		}
	}
	elsif ($cmd eq "MODE") {
		irc_log($irc, $channel, "--- mode: ($nick) @params");
	}
	elsif ($cmd eq "KICK") {
		irc_log($irc, $channel, "--- kick: $params[1] by $nick ($text) $channel");
	}

	$respond = $channel;
	$respond = $nick unless ($channel =~ /^#/);
	return({ 'cmd' => $cmd, 'nick' => $nick, 'server' => $serv, 'channel' => $channel, 'respond' => $respond, 'msg' => [ @params ], 'text' => $text });
}

### LOGGING FUNCTIONS ###

sub irc_check_all_logs {
	local($irc) = @_;
	my $time = get_time();
	my $temp_time = $irc_time;

	foreach (channel_list($irc->{'channels'})) {
		if ($irc_time->{'day'} != $time->{'day'}) {
			irc_end_logs($irc, $_);
			$irc_time = $time;
			irc_start_logs($irc, $_);
			$irc_time = $temp_time;
		}
	}
	$irc_time = get_time();
}

sub irc_start_logs {
	local($irc, $channel) = @_;
	my $time = get_time();
	return if (irc_open_logs($irc, $channel, $irc_time));
	printf FILE ("%02d:%02d:%02d --- log started ($channel) %02d-%02d-%02d\n", $time->{'hour'}, $time->{'min'}, $time->{'sec'}, $time->{'year'}, $time->{'month'}, $time->{'day'});
	irc_close_logs();
}

sub irc_end_logs {
	local($irc, $channel) = @_;
	my $time = get_time();
	return if (irc_open_logs($irc, $channel, $irc_time));
	printf FILE ("%02d:%02d:%02d --- log ended ($channel) %02d-%02d-%02d\n", $time->{'hour'}, $time->{'min'}, $time->{'sec'}, $time->{'year'}, $time->{'month'}, $time->{'day'});
	irc_close_logs();
}

sub irc_open_logs {
	local($irc, $channel, $time) = @_;
	if ($irc->{'connected'} and (channel_get_option($irc->{'channels'}, $channel, "log_enable", $irc->{'log_enable'}))[0]) {
		$channel =~ s/#//;
		mkdir "$irc->{'logdir'}/$channel" if (!(-e "$irc->{'logdir'}/$channel"));
		$file = sprintf("$irc->{'logdir'}/$channel/%02d-%02d-%02d.txt", $time->{'year'}, $time->{'month'}, $time->{'day'});
		open(FILE, ">>$file") or (status_log("Cannot Open Log $file") and return(-1));
		return(0);
	}
	return(-1);
}

sub irc_close_logs {
	close FILE;
}

1;

### END OF IRC.PM ###
