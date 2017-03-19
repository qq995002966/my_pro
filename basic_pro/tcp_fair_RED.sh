#!/bin/bash

# Note: Mininet must be run as root.  So invoke this shell script
# using sudo.

if [ "$#" -lt 3 ]
then
  echo "Usage: `basename $0` bw label <RED table file>" 1>&2
  exit 1
fi

bw=$1
file=$3
if [ ! -f "$file" ]
then
	echo "file $file does not exist" 1>&2
	exit 2
fi

label=$2

readarray -t lines < "$file"
for params in "${lines[@]}"; do
	# skip empty lines or lines that start with #
	if (( ${#params} == 0 )) || [[ ${params} == "#"* ]]
	then
		continue
	fi
	./tcp_fair_loop.sh ${bw} ${label}-${params}
done 
