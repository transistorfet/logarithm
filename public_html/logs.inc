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
	$logs = $logs ? $logs : $log_dir;
	if ($channel && is_dir("$logs/$channel") && ($dir = opendir("$logs/$channel"))) {
		while ($filename = readdir($dir)) {
			search_log_file("$logs/$channel/$filename", $phrase);
		}
		closedir($dir);
		return(true);
	}
	return(false);
}

function search_log_file ($filename, $phrase) {
	preg_match("/.*\/(\w*)\/(\S*)\.txt$/", $filename, $entry);
	if ($file = fopen($filename, "r")) {
		while ($line = fgets($file)) {
			if (strstr($line, $phrase)) {
				$line = rtrim($line);
				$line = str_replace("<", "&lt;", $line);
				$line = str_replace(">", "&gt;", $line);
				echo("<a href=\"chat.php?channel=$entry[1]&date=$entry[2]\">$entry[2]</a> $line<br>\n");
			}
		}
		fclose($file);
		return(true);
	}
	return(false);
}

?>