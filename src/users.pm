#
# Module Name:	users.pm
# Version:	0.6
# Description:	Users Manager
#

package users;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(
	user_create
	user_join
	user_leave
	user_quit
	user_changenick
	user_purge_channel
	user_register
	user_unregister
	user_change_password
	user_change_hostmask
	user_login
	user_is_authorized
	user_check_hostmask
	user_get_access
	user_add_access
	user_remove_access
	user_modify_access
);


### USERS.PM START ###

use csv;
use misc;

sub user_create {
	return({ });
}

sub user_join {
	local($users, $chan, $nick, $mask) = @_;
	if (defined($users->{$nick})) {
		foreach $user_channel (@{ $users->{$nick}->{'channels'} }) {
			return if ($user_channel eq $chan);
		}
		push(@{ $users->{$nick}->{'channels'} }, $chan);
	}
	else {
		$users->{$nick} = { 'authorized' => 0, 'channels' => [ $chan ] };
		user_check_hostmask($nick, $mask);
	}
}

sub user_leave {
	local($users, $chan, $nick) = @_;
	if (defined($users->{$nick})) {
		for $j (0..$#{ $users->{$nick}->{'channels'} }) {
			if ($users->{$nick}->{'channels'}->[$j] eq $chan) {
				splice(@{ $users->{$nick}->{'channels'} }, $j, 1);
				delete($users->{$nick}) if (scalar(@{ $users->{$nick}->{'channels'} }) == 0);
				return;
			}
		}
	}
}

sub user_quit {
	local($users, $nick) = @_;
	if (defined($users->{$nick})) {
		my @user = @{ $users->{$nick}->{'channels'} };
		delete($users->{$nick});
		return(@user);
	}
	return("");
}

sub user_changenick {
	local($users, $oldnick, $newnick) = @_;
	if (defined($users->{$oldnick})) {
		my @user = @{ $users->{$oldnick}->{'channels'} };
		$users->{$newnick} = $users->{$oldnick};
		delete($users->{$oldnick});
		return(@user);
	}
	return("");
}

sub user_purge_channel {
	local($users, $channel) = @_;

	foreach $key (keys(%users)) {
		user_leave($key, $channel);
	}
	return(0);
}

sub user_register {
	local($users, $nick, $password) = @_;
	return(-1) if (!defined($users->{$nick}));
	$password = crypt($password, $nick);
	return(-1) if (scalar(csv_search("", "passwd", ":", $nick)) > 0);
	return(csv_add("", "passwd", ':', $nick, $password, ""));
}

sub user_unregister {
	local($users, $nick) = @_;
	return(-1) if (!(defined($users->{$nick}) and $users->{$nick}->{'authorized'}));
	return(csv_remove("", "passwd", ':', $nick));
}

sub user_change_password {
	local($users, $nick, $password) = @_;
	return(-1) if (!(defined($users->{$nick}) and $users->{$nick}->{'authorized'}));
	$password = crypt($password, $nick);
	my ($entry) = csv_search("", "passwd", ':', $nick);
	($check, $blank, @rest) = @{ $entry };
	return(-1) if ($check ne $nick);
	return(csv_modify("", "passwd", ':', $nick, $password, @rest));
}

sub user_change_hostmask {
	local($users, $nick, $mask) = @_;
	return(-1) if (!(defined($users->{$nick}) and $users->{$nick}->{'authorized'}));
	my ($entry) = csv_search("", "passwd", ':', $nick);
	($check, $password, $blank, @rest) = @{ $entry };
	return(-1) if ($check ne $nick);
	return(csv_modify("", "passwd", ':', $nick, $password, $mask, @rest));
}

sub user_login {
	local($users, $nick, $password) = @_;
	return(-1) if (!defined($users->{$nick}));
	$password = crypt($password, $nick);
	my ($entry) = csv_search("", "passwd", ':', $nick);
	return(-1) if (($entry->[0] ne $nick) or ($entry->[1] ne $password));
	$users->{$nick}->{'authorized'} = 1;
	return(0);
}

sub user_is_authorized {
	local($users, $nick) = @_;
	return(0) if (!defined($users->{$nick}));
	return($users->{$nick}->{'authorized'});
}

sub user_check_hostmask {
	local($users, $nick, $mask) = @_;
	return(-1) if (!defined($users->{$nick}));
	my ($entry) = csv_search("", "passwd", ':', $nick);
	my $regex = encode_regex($entry->[2]);
	return(-1) unless (($entry->[0] eq $nick) and ($mask =~ /$regex/));
	$users->{$nick}->{'authorized'} = 1;
	return(0);
}

sub user_get_access {
	local($users, $channel, $nick) = @_;
	return(0) unless (defined($users->{$nick}) and $users->{$nick}->{'authorized'});
	my ($entry) = csv_search($channel, "access", ':', $nick);
	return(1) if ($entry->[0] ne $nick);
	return($entry->[1]);
}

sub user_add_access {
	local($users, $channel, $nick, $privs) = @_;
	return if ($privs == 0);
	return(-1) if (scalar(csv_search($channel, "access", ":", $nick)) > 0);
	return(csv_add($channel, "access", ':', $nick, $privs));
}

sub user_remove_access {
	local($users, $channel, $nick) = @_;
	return(csv_remove($channel, "access", ':', $nick));
}

sub user_modify_access {
	local($users, $channel, $nick, $privs) = @_;
	my ($entry) = csv_search($channel, "access", ':', $nick);
	($nick, @values) = @{ $entry };
	$values[0] = $privs;
	return(csv_modify($channel, "access", ':', $nick, @values));
}


1;

### END OF USERS.PM ###
