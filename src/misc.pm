#
# Module Name:	misc.pm
# Version:	0.6
# Description:	Miscellaneous Functions
#

package misc;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(status_log encode_regex strip_return strip_colour get_time);


### MISC.PM START ###

my $misc_status_file = "status.log";

sub status_log {
	local($msg) = @_;
	open(STATUS, ">>$misc_status_file") or return(-1);
	print "$msg\n";
	my $time = get_time();
	printf STATUS ("%02d-%02d-%02d %02d:%02d:%02d : ", $time->{'year'}, $time->{'month'}, $time->{'day'}, $time->{'hour'}, $time->{'min'}, $time->{'sec'});
	print STATUS "$msg\n";
	close(STATUS);
	return(0);
}

sub encode_regex {
	local($str) = @_;
	$str =~ s/(\\|\/|\^|\.|\~|\@|\$|\||\(|\)|\[|\]|\+|\?|\{|\})/\\$1/g;
	$str =~ s/\*/\.\*/g;
	return($str);
}

sub strip_return {
	local($str) = @_;
	$str =~ s/(\r|)\n//;
	return($str);
}

sub strip_colour {
	local($msg) = @_;
	$msg =~ s/(\x03)+\d{1,2}(,\d{1,2})?//g;
	$msg =~ s/(\x03)*//g;
	$msg =~ s/(\x02|\x06|\x07|\x16)//g;
	return($msg);
}

sub get_time {
	local($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
	$mon++;
	$year =~ s/^\d?//;
	return( { 'sec' => $sec, 'min' => $min, 'hour' => $hour, 'month' => $mon, 'year' => $year, 'day' => $mday, 'wday' => $wday } );
}


1;

### END OF MISC.PM ###
