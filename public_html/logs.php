<html>
<head>
</head>
<body>
<?php
	require_once("logs.inc");

	if (isset($_GET['channel'])) {
		print_logs($_GET['channel'], $_GET['date'], "");
	}
	else {
		echo("<h2>Channels</h2>\n<hr>\n");
		print_channels("");
		echo("<hr>\n");
	}
?>
</body>
</html>
