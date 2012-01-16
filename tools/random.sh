#!/bin/bash

# Helper script generating random events. Simulates multiple senders
# be forking one background process for each, sleeping in between 
# requests.
#
# Require curl to work.

################################################################################
# Configuration
SENDER_COUNT=3				# nr of concurrent hosts
CHAIN_LEN=3				# length of invocation chain
SERVER="http://localhost:8080"		# the SpurTracer server
PIDFILE=/tmp/spt_random.pid
#
################################################################################
# Error rates: average number of requests before error is simulated
#
# Error rates per component
ERROR_RATE_COMP1=0
ERROR_RATE_COMP2=10
ERROR_RATE_COMP3=2000
#
# Error rates per host
ERROR_RATE_HOST1=0
ERROR_RATE_HOST2=0
ERROR_RATE_HOST3=200
#
# Error rates per interface
ERROR_RATE_INTERFACE1=0
ERROR_RATE_INTERFACE2=100
################################################################################

trap "cat $PIDFILE | xargs kill -9; exit" SIGINT SIGTERM

################################################################################
# Determine wether to simulate an error
#
# $1	name of error rate setting
#
# Returns 0 for error event (1 otherwise)
################################################################################
simulate_error() {
	frequency=$(eval echo \$$1)

	if [ "$frequency" == "" ]; then
		return 1
	fi

	if [ ! $frequency -gt 0 ]; then
		return 1
	fi

	result=$(($RANDOM % $frequency))
	if [ $result -eq 1 ]; then
		return 0
	fi

	return 1
}

if [ "$1" == "" ]; then
	# Fork mode
	echo "Concurrency set to $SENDER_COUNT..."
	rm $PIDFILE 2>/dev/null
	i=0
	while [ $i -lt $SENDER_COUNT ]; 
	do
		echo "Starting sender $i..."
		( $0 $i ) &
		echo "$! " >> $PIDFILE
		i=$(($i + 1))
	done

	while [ 1 ]; do
		sleep 100000
	done
else 
	hostNr=$1
	theHost=host$1
	ctxt=$$_$(($RANDOM % 100))
	nr=1

	# Worker mode
	while [ 1 ]; do
		j=1
		while [ $j -le $CHAIN_LEN ]; do
	
			sleep $(($RANDOM % 5 + 1))
			curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=started&desc=test+request"

			sleep 4
		
			steps=$(($RANDOM % 4 + 1))
			i=0
			while [ $i -lt $steps ];
			do
				i=$(($i + 1))
				sleep $(($RANDOM % 5 + 1))
				curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=running&desc=step $i/$steps"

				if simulate_error ERROR_RATE_COMP$j; then
					curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=failed&desc=simulated+component+error"
					break 2
				fi

				if simulate_error ERROR_RATE_HOST$hostNr; then
					curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=failed&desc=simulated+host+error"
					break 2
				fi

			done

			if [ $j -lt $CHAIN_LEN ]; then
				# Trigger interface
				curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=c&ctxt=${ctxt}_${nr}&newcomponent=comp$(($j + 1))&newctxt=${ctxt}_${nr}"
	
				sleep 2
			fi
	
			curl -s "$SERVER/set?host=$theHost&component=comp$j&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=finished&desc=test+request+done"
		
			simulate_error ERROR_RATE_INTERFACE$j && break

			j=`expr $j + 1`
		done
		nr=$(($nr + 1))
	done
fi


