#
# Module Name:	misc.pm
# Version:	0.6
# Description:	Miscellaneous Functions
#

package misc;

require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(
	status_log
	encode_regex
	strip_return
	get_time
	create_file_directory
	create_directory
	copy_file
);

use strict;

my $misc_status_file = "../logs/status.log";

sub status_log {
	my ($msg) = @_;

	open(STATUS, ">>$misc_status_file") or return(-1);
	print "$msg\n";
	my $time = get_time();
	printf STATUS ("%02d-%02d-%02d %02d:%02d:%02d : ", $time->{'year'}, $time->{'month'}, $time->{'day'}, $time->{'hour'}, $time->{'min'}, $time->{'sec'});
	print STATUS "$msg\n";
	close(STATUS);
	return(0);
}

sub encode_regex {
	my ($str) = @_;

	$str =~ s/(\\|\/|\^|\.|\~|\@|\$|\||\(|\)|\[|\]|\+|\?|\{|\})/\\$1/g;
	$str =~ s/\*/\.\*/g;
	return($str);
}

sub strip_return {
	my ($str) = @_;

	$str =~ s/(\r|)\n$//;
	return($str);
}

sub get_time {
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time);
	$mon++;
	$year =~ s/^\d?//;
	return( { 'sec' => $sec, 'min' => $min, 'hour' => $hour, 'month' => $mon, 'year' => $year, 'day' => $mday, 'wday' => $wday } );
}

sub create_file_directory {
	my ($file) = @_;

	$file =~ /^(.*)(\\|\/)(.*?)$/;
	create_directory($1) if ($1);
}

sub create_directory {
	my ($dir) = @_;

	my $rel = "";
	foreach (split(/(\/|\\)/, $dir)) {
		$rel .= $_;
		mkdir($rel) if (!(-e $rel));
	}
}

sub copy_file {
	my ($source, $dest, $overwrite) = @_;

	my $data;
	return(-1) if (!$overwrite and (-e $dest));
	open(FILE, $source) or return(-1);
	{
		$/ = undef;
		$data = <FILE>;
	}
	close(FILE);

	open(FILE, ">$dest") or return(-1);
	print FILE $data;
	close(FILE);
	return(0);
}

1;

