<?php

$log_dir = "../logs";

function print_log_search ($channel, $logs) {
	echo("<form method=\"GET\">\n");
	echo("<input type=\"hidden\" name=\"channel\" value=\"$_GET[channel]\">\n");
	echo("<input type=\"text\" name=\"q\" size=\"80\" value=\"$_GET[q]\">\n");
	echo("<input type=\"submit\" value=\"Search\">\n");
	echo("</form>\n");
	if ($_GET['q']) {
		search_logs($channel, $logs, stripslashes($_GET['q']));
	}
}

function search_logs ($channel, $logs, $phrase) {
	global $log_dir;
	$hits = 0;
	$logs = $logs ? $logs : $log_dir;
	if ($channel && is_dir("$logs/$channel") && ($dir = opendir("$logs/$channel"))) {
		while ($filename = readdir($dir)) {
			$hits += search_log_file("$logs/$channel/$filename", $phrase);
		}
		closedir($dir);
		echo("$hits hits found<br>\n");
		return(true);
	}
	return(false);
}

function search_log_file ($filename, $phrase) {
	$hits = 0;
	preg_match("/.*\/(\w*)\/(\S*)\.txt$/", $filename, $entry);
	if ($file = fopen($filename, "r")) {
		while ($line = fgets($file)) {
			if (stristr($line, $phrase)) {
				$hits++;
				$line = rtrim($line);
				$line = str_replace("<", "&lt;", $line);
				$line = str_replace(">", "&gt;", $line);
				echo("<a href=\"chat.php?channel=$entry[1]&date=$entry[2]\">$entry[2]</a> $line<br>\n");
			}
		}
		fclose($file);
		return($hits);
	}
	return(0);
}

?>
