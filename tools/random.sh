#!/bin/bash

# Helper script generating random events. Simulates multiple senders
# be forking one background process for each, sleeping in between 
# requests.
#
# Require curl to work.

# Configuration
SENDER_COUNT=3				# nr of concurrent hosts
CHAIN_LEN=3				# length of invocation chain
SERVER="http://localhost:8080"		# the SpurTracer server
PIDFILE=/tmp/spt_random.pid

trap "cat $PIDFILE | xargs kill -9; exit" SIGINT SIGTERM

if [ "$1" == "" ]; then
	# Fork mode
	echo "Concurrency set to $SENDER_COUNT..."
	rm $PIDFILE 2>/dev/null
	i=0
	while [ $i -lt $SENDER_COUNT ]; 
	do
		echo "Starting sender $i..."
		( $0 host$i ) &
		echo "$! " >> $PIDFILE
		i=$(($i + 1))
	done

	while [ 1 ]; do
		sleep 100000
	done
else 
	theHost=$1
	ctxt=$$_$(($RANDOM % 100))
	nr=1

	# Worker mode
	while [ 1 ]; do
		j=1
		while [ $j -le $CHAIN_LEN ]; do
	
			sleep $(($RANDOM % 20 + 3))
			curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=started&desc=test+request"

			sleep 4
		
			steps=$(($RANDOM % 4 + 1))
			i=0
			while [ $i -lt $steps ];
			do
				i=$(($i + 1))
				sleep $(($RANDOM % 5 + 1))
				curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=running&desc=step $i/$steps"
			done

			if [ $j -lt $CHAIN_LEN ]; then
				# Trigger interface
				curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=c&ctxt=${ctxt}_${nr}&newcomponent=comp$(($j + 1))&newctxt=${ctxt}_${nr}"
	
				sleep 2
			fi
	
			curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=finished&desc=test+request+done"
	
	
			j=`expr $j + 1`

		done
		nr=$(($nr + 1))
	done
fi


