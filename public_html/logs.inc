<?php

require_once("misc.inc");

$log_dir = "../logs";

function print_channels ($logs) {
	global $log_dir;
	$logs = $logs ? $logs : $log_dir;
	if (is_dir($logs) && ($dir = opendir($logs))) {
		echo("<ul>\n");
		while ($channel = readdir($dir)) {
			echo("<li><a href=\"$_SERVER[PHP_SELF]?channel=$channel\">#$channel</a></li>\n");
		}
		echo("</ul>\n");
	}
}

function print_logs ($channel, $date, $logs) {
	global $log_dir;
	if (!$channel) {
		return(false);
	}
	$date = $date ? $date : date("y-m-d");
	$logs = $logs ? $logs : $log_dir;

	$link = "";
	$_GET['date'] = date("y-m-d", strtotime("-1 day", strtotime($date)));
	if (file_exists("$logs/$channel/$_GET[date].txt")) {
		$prev_link = build_query($_SERVER['PHP_SELF'], $_GET);
		$link .= "<a href=\"$prev_link\">Previous Day's Logs</a> | ";
	}

	$_GET['date'] = date("y-m-d", strtotime("+1 day", strtotime($date)));
	if (file_exists("$logs/$channel/$_GET[date].txt")) {
		$next_link = build_query($_SERVER['PHP_SELF'], $_GET);
		$link .= "<a href=\"$next_link\">Next Day's Logs</a> | ";
	}
	$link .= "<a href=\"search.php?channel=$channel\">Search Logs</a>";

	$filename = "$logs/$channel/$date.txt";
	if (file_exists($filename) && ($file = fopen($filename, "r"))) {
		echo("$link<br>\n");
		echo("<table cellspacing=0>\n");
		while ($line = fgets($file)) {
			$line = rtrim($line);
			$line = str_replace("<", "&lt;", $line);
			$line = str_replace(">", "&gt;", $line);
			$line = preg_replace("/(http:\S*)/", "<a href=\"\\1\">\\1</a>", $line);
			echo("<tr><td>$line</td></tr>\n");
		}
		echo("</table>\n");
		echo("$link\n");
		fclose($file);
		return(true);
	}
	return(false);
}

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
		$files = array();
		while ($filename = readdir($dir)) {
			$files[] = $filename;
		}
		rsort($files);
		foreach ($files as $filename) {
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
				echo("<a href=\"logs.php?channel=$entry[1]&date=$entry[2]\">$entry[2]</a> $line<br>\n");
			}
		}
		fclose($file);
		return($hits);
	}
	return(0);
}

?>
