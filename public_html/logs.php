<?php
	require_once("logs.inc");

	if (isset(_GET['channel'])) {
		print_logs($_GET['channel'], $_GET['date'], "");
	}
	else {
		print_channels("");
	}
?>
