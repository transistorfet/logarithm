#
# Module Name:	csv.pm
# Version:	0.6
# Description:	CSV Module
#

package csv;
require Exporter;
@ISA 	= qw(Exporter);
@EXPORT = qw(csv_add csv_remove csv_modify csv_search);


### CSV.PM START ###

use misc;

my $etc_dir = "../etc";

sub csv_add {
	my($channel, $file, $delim, $value, @entries) = @_;

	$delim = ":" unless ($delim);
	my $dir = csv_get_directory($channel);

	open(FILE, ">>$dir/$file") or return(-1);
	print FILE join($delim, $value, @entries) . "\r\n";
	close(FILE);
	return(0);
}

sub csv_remove {
	my($channel, $file, $delim, $value) = @_;

	$delim = ":" unless ($delim);
	$value = lc($value);
	my $dir = csv_get_directory($channel);

	open(FILE, "$dir/$file") or return(-1);
	open(TMP, ">$dir/$file.tmp") or return(-1);
	while ($line = <FILE>) {
		($name) = split($delim, $line);
		next if ($value eq lc($name));
		print TMP $line;
	}
	close(TMP);
	close(FILE);
	unlink("$dir/$file");
	rename("$dir/$file.tmp", "$dir/$file");
	return(0);
}

sub csv_modify {
	my($channel, $file, $delim, $value, @entries) = @_;

	$delim = ":" unless ($delim);
	$value = lc($value);
	my $dir = csv_get_directory($channel);

	open(FILE, "$dir/$file") or return(-1);
	open(TMP, ">$dir/$file.tmp") or return(-1);
	while ($line = <FILE>) {
		($name) = split($delim, $line);
		if ($value eq lc($name)) {
			print TMP join($delim, $name, @entries) . "\r\n";
		}
		else {
			print TMP $line;
		}
	}
	close(TMP);
	close(FILE);
	unlink("$dir/$file");
	rename("$dir/$file.tmp", "$dir/$file");
	return(0);
}

sub csv_search {
	my($channel, $file, $delim, $value) = @_;

	$delim = ":" unless ($delim);
	$value = lc($value) if (defined($value));
	my $dir = csv_get_directory($channel);

	my @results = ();
	my $filename = "$dir/$file";
	for (0..1) {
		if (open(FILE, "$filename")) {
			while (<FILE>) {
				$_ = strip_return($_);
				my @entry = split($delim, $_);
				if (!defined($value) or ($entry[0] and (lc($entry[0]) eq $value))) {
					push(@results, \@entry);
				}
			}
			close(FILE);
			last unless ($channel);
		}
		$filename = "$etc_dir/$file";
	}
	return(@results);
}

### LOCAL FUNCTIONS ###

sub csv_get_directory {
	local($channel) = @_;

	my $dir = $etc_dir;
	return($dir) unless ($channel =~ /^\#/);
	$channel =~ s/^\#//;
	$dir = "$dir/$channel" if ($channel);
	mkdir($dir) unless (-e $dir);
	return($dir);
}


1;

### END OF CSV.PM ###
