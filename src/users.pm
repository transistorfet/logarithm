#
# Module Name:	users.pm
# Description:	Users Manager
#

package users;

use strict;

use csv;
use misc;

my $config_dir = "../etc";
my $passwd_file = csv->open_file("$config_dir/passwd", ':', 1);

sub new {
	my ($this, $file) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	return($self);
}

sub join_channel {
	my ($self, $channel, $nick, $mask) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	if (defined($self->{ $nick })) {
		foreach my $user_channel (@{ $self->{ $nick }->{'channels'} }) {
			return if ($user_channel eq $channel);
		}
		push(@{ $self->{ $nick }->{'channels'} }, $channel);
	}
	else {
		$self->{ $nick } = {
			'authorized' => 0,
			'channels' => [ $channel ]
		};
		$self->check_hostmask($nick, $mask) if (defined($mask));
	}
}

sub leave_channel {
	my ($self, $channel, $nick) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	if (defined($self->{ $nick })) {
		for my $i (0..scalar(@{ $self->{ $nick }->{'channels'} })) {
			if ($self->{ $nick }->{'channels'}->[$i] eq $channel) {
				splice(@{ $self->{ $nick }->{'channels'} }, $i, 1);
				delete($self->{ $nick }) if (scalar(@{ $self->{ $nick }->{'channels'} }) == 0);
				return;
			}
		}
	}
}

sub quit {
	my ($self, $nick) = @_;

	$nick = lc($nick);
	if (defined($self->{ $nick })) {
		my @channels = @{ $self->{ $nick }->{'channels'} };
		delete($self->{ $nick });
		return(@channels);
	}
	return("");
}

sub change_nick {
	my ($self, $oldnick, $newnick) = @_;

	$oldnick = lc($oldnick);
	$newnick = lc($newnick);
	if (defined($self->{ $oldnick })) {
		my @channels = @{ $self->{ $oldnick }->{'channels'} };
		return(@channels) if ($newnick eq $oldnick);
		$self->{ $newnick } = $self->{ $oldnick };
		delete($self->{ $oldnick });
		return(@channels);
	}
	return("");
}

sub purge_channel {
	my ($self, $channel) = @_;

	$channel = lc($channel);
	foreach my $nick (keys(%{ $self })) {
		$self->leave_channel($channel, $nick);
	}
	return(0);
}


sub register {
	my ($self, $nick, $password) = @_;

	$nick = lc($nick);
	$password = crypt($password, $nick);
	return(-1) if ($passwd_file->find_entry($nick));
	$passwd_file->add_entry($nick, $password, "");
	return(0);
}

sub unregister {
	my ($self, $nick) = @_;

	$nick = lc($nick);
	$passwd_file->remove_entry($nick);
}

sub change_password {
	my ($self, $nick, $password) = @_;

	$nick = lc($nick);
	return(-1) unless (defined($self->{ $nick }) and $self->{ $nick }->{'authorized'});
	$password = crypt($password, $nick);
	my @entry = $passwd_file->find_entry($nick);
	return(-1) unless (lc($entry[0]) eq $nick);
	$passwd_file->replace_entry($nick, $password, $entry[2]);
}

sub change_hostmask {
	my ($self, $nick, $mask) = @_;

	$nick = lc($nick);
	return(-1) unless (defined($self->{ $nick }) and $self->{ $nick }->{'authorized'});
	my @entry = $passwd_file->find_entry($nick);
	return(-1) unless (lc($entry[0]) eq $nick);
	$passwd_file->replace_entry($nick, $entry[1], $mask);
}

sub login {
	my ($self, $nick, $password) = @_;

	$nick = lc($nick);
	return(-1) unless (defined($self->{ $nick }));
	$password = crypt($password, $nick);
	my @entry = $passwd_file->find_entry($nick);
	return(-1) unless ((lc($entry[0]) eq $nick) and ($entry[1] eq $password));
	$self->{ $nick }->{'authorized'} = 1;
	return(0);
}

sub is_authorized {
	my ($self, $nick) = @_;

	$nick = lc($nick);
	return(0) unless (defined($self->{ $nick }));
	return($self->{ $nick }->{'authorized'});
}

sub check_hostmask {
	my ($self, $nick, $mask) = @_;

	$nick = lc($nick);
	return(-1) unless (defined($self->{ $nick }));
	my @entry = $passwd_file->find_entry($nick);
	my $regex = encode_regex($entry[2]);
	return(-1) unless ((lc($entry[0]) eq $nick) and ($mask =~ /$regex/));
	$self->{ $nick }->{'authorized'} = 1;
	return(0);
}


sub get_access {
	my ($self, $channel, $nick) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	$channel =~ s/^#+//;
	return(0) unless (defined($self->{ $nick }) and $self->{ $nick }->{'authorized'});
	my $access_file = csv->open_file("$config_dir/access", ':', 1);
	my @entry = $access_file->find_entry($nick);
	unless ($entry[0]) {
		$access_file = csv->open_file("$config_dir/$channel/access", ':', 1);
		@entry = $access_file->find_entry($nick);
	}
	return(1) unless (lc($entry[0]) eq $nick);
	return($entry[1]);
}

sub add_access {
	my ($self, $channel, $nick, $privs) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	$channel =~ s/^#+//;
	return if ($privs == 0);
	my $access_file = csv->open_file("$config_dir/$channel/access", ':', 1);
	my @entry = $access_file->find_entry($nick);
	return(-1) if (lc($entry[0]) eq $nick);
	$access_file->add_entry($nick, $privs);
}

sub remove_access {
	my ($self, $channel, $nick) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	$channel =~ s/^#+//;
	my $access_file = csv->open_file("$config_dir/$channel/access", ':', 1);
	$access_file->remove_entry($nick);
}

sub modify_access {
	my ($self, $channel, $nick, $privs) = @_;

	$nick = lc($nick);
	$channel = lc($channel);
	$channel =~ s/^#+//;
	return if ($privs == 0);
	my $access_file = csv->open_file("$config_dir/$channel/access", ':', 1);
	my @entry = $access_file->find_entry($nick);
	return(-1) unless (lc($entry[0]) eq $nick);
	$access_file->replace_entry($nick, $privs);
}

1;

