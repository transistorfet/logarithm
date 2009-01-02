#
# Module Name:	Handler.pm
# Description:	Handler Object (calls a function to handle an event)
#

package Handler;

use strict;
use warnings;

use Misc;

sub new {
	my ($this, $func, @params) = @_;
	my $class = ref($this) || $this;
	my $self = { };
	bless($self, $class);
	$self->{'package'} = caller();
	$self->{'func'} = $func;
	$self->{'params'} = [ @params ];
	return($self);
}

sub handle {
	my ($self, @params) = @_;
	my $ret = eval "$self->{'package'}::$self->{'func'}(\@{ \$self->{'params'} }, \@params);";
	status_log($@) if ($@);
	return($ret);
}

sub package {
	my $self = shift(@_);
	# TODO this is read only right?
	#$self->{'package'} = shift(@_) if (scalar(@_));
	return($self->{'package'});
}

1;

