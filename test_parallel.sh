#!/bin/bash

# set -m 

do_regurgitate()
{
	if [[ $1 =~ ^[0-9a-f]$ ]]; then 
		echo "$1"
		sleep 1
		echo "do_regurgitate: $1"
	fi
}

for char in 0 1 2 3 4 5 6 7 8 9 a b c d e f; do
	echo "loop: $char"
	do_regurgitate "$char" &
done

# while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done
wait `jobs -p`