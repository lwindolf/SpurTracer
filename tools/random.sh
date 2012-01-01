#!/bin/bash


# Helper script generating random events. Simulates multiple senders
# be forking one background process for each, sleeping in between 
# requests.
#
# Require curl to work.

# Configuration
SENDER_COUNT=3
SERVER="http://localhost:8080"		# the SpurTracer server

if [ "$1" == "" ]; then
	# Fork mode
	echo "Concurrency set to $SENDER_COUNT..."
	i=0
	while [ $i -lt $SENDER_COUNT ]; 
	do
		echo "Starting sender $i..."
		( $0 host$i ) &
		i=$(($i + 1))
	done

	while [ 1 ]; do
		:
	done
else 
	theHost=$1
	ctxt=$(($RANDOM % 100))
	nr=1

	# Worker mode
	while [ 1 ]; do
		sleep $(($RANDOM % 20 + 3))
		curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=running&desc=test+request"
		nr=$(($nr + 1))
	done
fi
