<html>
<head>
<title>Definitions Page</title>
</head>
<body>

<h2>Definitions</h2>

<hr>
<br>

<?php
	require_once("defines.inc");
	$file = $channel ? "$channel/defines.lst" : "defines.lst";
	find_define("/home/logarithm/etc/$file", $def);
?>

<form action="define.php" method="get">
	Definition:
	<input type="text" name="def" size=30>
	<input type="submit" value="Lookup">
</form>

<hr>

<p><a href="./">Home</a><br>

</body>
</html>
