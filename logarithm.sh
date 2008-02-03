#!/bin/sh

cd src

while true
do
	echo "Starting Bot..."
	perl logarithm.pl;
	echo "Terminated.  Restarting..."
	sleep 15
done

