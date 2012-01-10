#!/bin/bash

# Helper script generating random events. Simulates multiple senders
# be forking one background process for each, sleeping in between 
# requests.
#
# Require curl to work.

# Configuration
SENDER_COUNT=3
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
		sleep $(($RANDOM % 20 + 3))
		curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=started&desc=test+request"

		sleep 4
		
		steps=$(($RANDOM % 5 + 1))
		i=0
		while [ $i -lt $steps ];
		do
			i=$(($i + 1))
			sleep $(($RANDOM % 5 + 1))
			curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=running&desc=step $i/$steps"
		done

		# Finally perform a context creation
		curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=c&ctxt=${ctxt}_${nr}&newcomponent=comp2&newctxt=${ctxt}_${nr}"

		sleep 2

		curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=finished&desc=test+request+done"

		sleep $(($RANDOM % 10 + 5))

		curl -s "$SERVER/set?host=$theHost&component=comp2&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=started&desc=test+invocation"
		sleep 5

		curl -s "$SERVER/set?host=$theHost&component=comp2&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=finished&desc=test+invocation+done"

		nr=$(($nr + 1))
	done
fi


