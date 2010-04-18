#
# Module Name:	Module.pm
# Description:	Command Modules Manager
#

package Module;

use strict;
use warnings;

use Misc;
use Handler;

use Command;

my $plugins_path = "Plugins";

my $modules = { };
my $current_owner = "core";

sub load {
	my ($this, $file) = @_;
	return(undef) unless (-e $file);

	my $package = _get_package_name($file);
	if (defined($modules->{ $package })) {
		$modules->{ $package }->_check_age();
		return ($modules->{ $package });
	}

	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'package'} = $package;
	$self->{'file'} = $file;
	$self->{'age'} = 0;
	$self->{'type'} = "module";
	$self->{'owner'} = $current_owner;
	$modules->{ $package } = $self;
	$self->_reload();
	return($self);
}

sub load_plugin {
	my ($this, $name) = @_;

	my $path = "$plugins_path/$name";
	my $file = "$path/Init.pm";
	my $self = load($this, $file);
	unless (defined($self)) {
		status_log("Error: Plugin \"$name\" not found.");
		return(undef);
	}
	return ($self) if ($self->{'type'} eq "plugin");	## Means we've already init'd so just return

	$self->{'owner'} = $self->{'package'};
	$self->{'type'} = "plugin";
	$self->{'path'} = $path;
	my $result = $self->call("init_plugin", $path);
	if (!defined($result) || $result < 0) {
		$self->release();
		status_log("Error: Failed initializing plugin \"$name\".");
		return(undef);
	}
	return($self);
}

sub release {
	my ($self) = @_;

	$self->call("release_plugin") if ($self->{'type'} eq "plugin");
	Command::purge($self->{'package'});
	Timer::purge($self->{'package'});
	Hook::purge($self->{'package'});
	return(0);
}

sub release_plugin {
	my ($class, $name) = @_;

	my $plugin = "$plugins_path/$name/Init.pm";
	my $module = Module::get_module($plugin);
	return(-1) unless (defined($module));
	$module->release();
	return(0);
}

sub call {
	my ($self, $func, @params) = @_;

	return(undef) unless eval("defined(*$self->{'package'}::${func}{CODE})");
	my $tmp_owner = $current_owner;
	$current_owner = $self->{'owner'};
	my $ret = eval "$self->{'package'}::$func(\@params);";
	status_log($@) if ($@);
	$current_owner = $tmp_owner;
	return($ret);
}

sub make_handler {
	my ($self, $func, @params) = @_;
	my $handler = Handler->new("call", $self, $func, @params);
	$handler->{'owner'} = $self->{'owner'};
	return($handler);
}


sub get_module {
	my ($name) = @_;
	return($modules->{ _get_package_name($name) }) if (-e $name);
	return($modules->{ $name });
}

sub get_module_list {
	return(keys(%{ $modules }));
}

sub reload_all {
	my @list = keys(%{ $modules });
	foreach my $name (@list) {
		$modules->{ $name }->_check_age();
	}
}

### Local Functions ###

sub _check_age {
	my ($self) = @_;

	if ($self->{'age'} > -M $self->{'file'}) {
		$self->_reload();
		$self->call("init_plugin", $self->{'path'}) if ($self->{'type'} eq "plugin");
	}
}

sub _reload {
	my ($self) = @_;

	do $self->{'file'};
	status_log($@) if ($@);
	$self->{'age'} = -M $self->{'file'};
}

sub _get_package_name {
	my ($file) = @_;
	$file =~ s/(\\|\/)/::/g;
	$file =~ s/\.pm$//;
	return($file);
}

1;

