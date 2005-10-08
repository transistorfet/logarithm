#
# Module Name:	module.pm
# Version:	0.6
# Description:	Command Modules Manager
#

package module;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(
	module_execute
	module_execute_alarms
	module_execute_chats
	module_purge_channel
	module_load
	module_get_info
	module_alias
	module_unalias
	module_register_alarm
	module_unregister_alarm
	module_reset_alarm
	module_register_chat
	module_unregister_chat
);


### MODULE.PM START ###

use irc;
use csv;
use misc;
use users;
use channels;

my %modules = ();
my %alarms = ();
my %chats = ();

sub module_execute {
	local($irc, $msg, $script, $func) = @_;

	return(-10) unless (channel_allowed($irc->{'channels'}, $msg->{'respond'}, $script));
	return(0) unless (module_load($script));
	if ($msg->{'nick'} eq $irc->{'nick'}) {
		$privs = (channel_get_option($irc->{'channels'}, $msg->{'respond'}, "say_access", 200))[0];
	}
	else {
		$privs = user_get_access($irc->{'users'}, $msg->{'respond'}, $msg->{'nick'});
	}
	$func = "do_$script" unless (defined($func));
	my $ret = eval "$func(\$irc, \$msg, \$privs);";
	status_log($@) if ($@);
	return($ret);
}

sub module_execute_alarms {
	local($irc) = @_;

	foreach $key (keys(%alarms)) {
		if ((time() - $alarms{$key}->{'start'}) >= $alarms{$key}->{'seconds'}) {
			module_execute($irc, $alarms{$key}->{'param'}, $alarms{$key}->{'script'}, $alarms{$key}->{'func'});
			$alarms{$key}->{'start'} = time();
		}
	}
}

sub module_execute_chats {
	local($irc, $msg) = @_;

	foreach $key (keys(%chats)) {
		if (($chats{$key}->{'channel'} eq "") or ($chats{$key}->{'channel'} eq $msg->{'channel'})) {
			if (($chats{$key}->{'cmds'} eq "") or ($msg->{'cmd'} =~ /\Q$chats{$key}->{'cmds'}\E/)) {
				module_execute($irc, $msg, $chats{$key}->{'script'}, $chats{$key}->{'func'});
			}
		}
	}
}

sub module_purge_channel {
	local($channel) = @_;

	foreach (keys(%chats)) {
		if (/.*;$channel/i) {
			($script, $func, $chan) = split(";", $_);
			module_unregister_chat($script, $func, $chan);
		}
	}
}

sub module_load {
	local($script) = @_;
	local($program) = "";

	if (defined($modules{$script})) {
		my $age = -M $modules{$script}->{'file'};
		if ($modules{$script}->{'age'} > $age) {
			delete($modules{$script});
		}
		else {
			return(1);
		}
	}

	if ($script =~ /\.pm$/) {
		$file = "plugin/$script";
	}
	else {
		$file = "cmd/$script";
		$file .= ".lm" unless ($file =~ /\.lm/);
	}

	return(0) unless (-e $file);

	open(FILE, $file) or return(0);
	while (<FILE>) {
		$program .= $_;
	}
	close(FILE);
	my $module_info = { };
	eval $program;
	status_log($@) if ($@);
	$modules{$script} = { 'name' => $script, 'file' => $file, 'age' => -M $file, 'info' => $module_info };
	return(1);
}

sub module_get_info {
	local($script) = @_;
	return(0) unless (module_load($script));
	return($modules{$script}->{'info'});
}

sub module_alias {
	local($script, $alias) = @_;

	return(0) unless (module_load($script));
	$modules{$alias} = $modules{$script};
	$modules{$alias}->{'name'} = $alias;
	return(1);
}

sub module_unalias {
	local($alias) = @_;

	return(1) if ($modules{$alias}->{'file'} =~ /\Q$alias\E/i);
	delete($modules{$alias});
	return(0);
}

sub module_register_alarm {
	local($script, $func, $name, $seconds, $param) = @_;
	return(1) if (defined($alarms{"$script;$func;$name"}));

	$alarms{"$script;$func;$name"} = { 'script' => $script, 'func' => $func, 'name' => $name, 'start' => time(), 'seconds' => $seconds, 'param' => $param };
	return(0);
}

sub module_unregister_alarm {
	local($script, $func, $name) = @_;

	delete($alarms{"$script;$func;$name"});
	return(0);
}

sub module_reset_alarm {
	local($script, $func, $name, $seconds, $param) = @_;
	$alarms{"$script;$func;$name"}->{'start'} = time();
	$alarms{"$script;$func;$name"}->{'seconds'} = $seconds if ($seconds);
	$alarms{"$script;$func;$name"}->{'param'} = $param if ($param);
	return(0);
}

sub module_register_chat {
	local($script, $func, $channel, $cmds) = @_;
	$chats{"$script;$func;$channel"} = { 'script' => $script, 'func' => $func, 'channel' => $channel, 'cmds' => $cmds };
	return(0);
}

sub module_unregister_chat {
	local($script, $func, $channel) = @_;
	delete($chats{"$script;$func;$channel"});
	return(0);
}


1;

### END OF MODULE.PM ###
