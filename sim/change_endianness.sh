#!/bin/bash

# Convert endinannes from a files with strings

# Usage 
# change_endiannes.sh [file]

myfile=$1
bytes=2

while IFS='' read -r LINE || [ -n "${LINE}" ];
do
	i=${#LINE}

	while [ $i -gt 0 ]
	do
	    i=$[$i-$bytes]
	    echo -n ${LINE:$i:$bytes}
	done

	echo

done < $myfile
