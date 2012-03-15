#!/bin/bash

# Helper script simulating a simple web shop with payment, delivery and
# messaging services. The idea is that we have
#
#	- 3 webservers "web[1-3]" running the "frontend" component
#	- 2 payment servers "pay[1-2]" running the "payment" component
#	- a single "delvr" host running the "delivery" component
#	- 2 messaging hosts "mail[1-2]" running the "messaging" component
#
# For each host and component the 
#
# Requires curl to work.

################################################################################
# Configuration
SERVER="http://localhost:8080"		# the SpurTracer server
PIDFILE=/tmp/spt_webshop.pid
SENDER_COUNT=3
SEQNR=0			# current request sequence (for "unique" ctxt ids)
#
################################################################################
# Error rates: average number of requests before error is simulated
#
# Error rates per component
ERROR_RATE_FRONTEND=0
ERROR_RATE_PAYMENT=20
ERROR_RATE_DELIVERY=4000
#
# Error rates per host
ERROR_RATE_web1=0
ERROR_RATE_web2=1000
ERROR_RATE_web3=0
ERROR_RATE_pay1=0
ERROR_RATE_pay2=0
ERROR_RATE_delvr=4000
ERROR_RATE_mail1=10000
ERROR_RATE_mail2=0
#
# Error rates per interface (FIXME: implement those below!)
ERROR_RATE_frontend_payment=0
ERROR_RATE_frontend_delivery=2000
ERROR_RATE_payment_messaging=0
ERROR_RATE_delivery_messaging=0
################################################################################

trap "cat $PIDFILE | xargs kill -9; exit" SIGINT SIGTERM

################################################################################
# Determine wether to simulate an error based on the host and component error 
# rate definitions
#
# $1	host name
# $2	component name
#
# Returns 0 for error event (1 otherwise)
################################################################################
simulate_error() {

	# Try host error rate
	local host_frequency=$(eval echo \$ERROR_RATE_$1)
	#echo "host $1 = $host_frequency"
	if [ "$host_frequency" == "" ]; then
		host_frequency=0
	fi

	# Try component error rate
	local comp_frequency=$(eval echo \$ERROR_RATE_$2)
	#echo "component $2 = $comp_frequency"
	if [ "$comp_frequency" == "" ]; then
		comp_frequency=0
	fi

	local frequency=$host_frequency
	if [ $frequency -lt $comp_frequency ]; then
		frequency=$comp_frequency
	fi

	if [ $frequency == 0 ]; then
		return 1
	fi

	#echo "effective: $frequency"
	result=$(($RANDOM % $frequency))
	if [ $result -eq 1 ]; then
		echo -n "e"
		return 0
	else
		echo -n "t"
	fi

	return 1
}

################################################################################
# Print the current Unix timestamp in [ms]
################################################################################
get_timestamp() {
	# Getting a [ms] timestamp is a bit complicated...
	nanos=`date +%N`
	nanos=`expr $nanos / 1000000`
	time=`date +%s`
	time=`printf "%d%03d" $time $nanos`
	echo "$time"
}

################################################################################
# Announce an interface
#
# $1	name of triggering host
# $2	name of triggering component
# $3	id of triggering context
# $4	name of triggered component
# $5	id of announced context
################################################################################
announce() {
	# FIXME: HTTP URI encode parameters 

	curl -s "${SERVER}/set?time=$(get_timestamp)&host=$1&type=c&component=$2&ctxt=$3&newcomponent=$4&newctxt=$5"
}

################################################################################
# Send a notification
#
# $1	name of triggering host
# $2	name of triggering component
# $3	id of triggering context
# $4	status (started|failed|finished)
# $5	optional description
################################################################################
notify() {
	# FIXME: HTTP URI encode parameters 

	curl -s "${SERVER}/set?time=$(get_timestamp)&host=$1&type=n&component=$2&ctxt=$3&status=$4&desc=$5"
}

################################################################################
# Return a unique ctxt id
################################################################################
get_ctxt_id() {
	echo "$$_$SEQNR"
}

################################################################################
# Simulate the mail systems
#
# $1	ctxt
################################################################################
run_messaging() {
	local host="mail$(($RANDOM % 2 + 1))"
	local ctxt=$1

	notify $host "messaging" $ctxt "started" "new message queued"

	sleep 2

	if simulate_error $host "MESSAGING"; then
		notify $host "messaging" $ctxt "failed" "simulated messaging failure"
	fi

	notify $host "messaging" $ctxt "finished" "complete"
}

################################################################################
# Simulate a delivery system
#
# $1	ctxt
################################################################################
run_delivery() {
	local host="delvry"
	local ctxt=$1

	notify $host "delivery" $ctxt "started" "new delivery"
	sleep 2

	if simulate_error $host "DELIVERY"; then
		notify $host "delivery" $ctxt "failed" "simulated delivery failure"
	else
		announce $host "delivery" $ctxt "messaging" msg_$ctxt
		sleep 1
		run_messaging msg_$ctxt
	fi

	notify $host "delivery" $ctxt "finished" "complete"
}

################################################################################
# Simulate a payment service
#
# $1	ctxt
################################################################################
run_payment() {
	local host="pay$(($RANDOM % 2 + 1))"
	local ctxt=$1

	notify $host "payment" $ctxt "started" "new VISA transaction"
	sleep 2

	# Note: The following notification messages are some foobar!
	notify $host "payment" $ctxt "running" "remote server: 135.136.137.138"
	notify $host "payment" $ctxt "running" "encryption schema: 3526+CGT/23-4"
	notify $host "payment" $ctxt "running" "transaction id: 1234-$$-890-AB-124"

	if simulate_error $host "PAYMENT"; then
		notify $host "payment" $ctxt "failed" "simulated payment failure"
	else
		announce $host "payment" $ctxt "messaging" msg_$ctxt
		sleep 1
		run_messaging msg_$ctxt
	fi

	notify $host "payment" $ctxt "finished" "payment completed"
}

################################################################################
# Simulate a web frontend
#
# $1	server index
################################################################################
run_frontend() {
	local host="web$1"
	local ctxt=`get_ctxt_id`

	notify $host "frontend" $ctxt "started" "new session"
	sleep 2

	notify $host "frontend" $ctxt "running" "add product 1"
	sleep 1

	if simulate_error $host "FRONTEND"; then
		notify $host "frontend" $ctxt "failed" "simulated frontend session failure"
	else
		notify $host "frontend" $ctxt "running" "add product 2"
		sleep 1

		announce $host "frontend" $ctxt "payment" pay_$ctxt
		sleep 1
		run_payment pay_$ctxt	# synchronous

		announce $host "frontend" $ctxt "delivery" delvry_$ctxt
		notify $host "frontend" $ctxt "finished" "success"

		sleep 2
		run_delivery delvry_$ctxt	# asynchronous (we finish directly after announcing)
	fi


}

if [ "$1" == "" ]; then
	# Fork mode
	echo "Concurrency set to $SENDER_COUNT..."
	rm $PIDFILE 2>/dev/null
	i=0
	while [ $i -lt $SENDER_COUNT ]; 
	do
		i=$(($i + 1))
		echo "Starting sender $i..."
		( $0 $i ) &
		echo "$! " >> $PIDFILE
	done

	while [ 1 ]; do
		sleep 100000
	done
else 
	# Worker mode

	SEQNR=$(($RANDOM % 1000))	# choose random start sequence number

	while [ 1 ]; do
		SEQNR=$(($SEQNR + 1))
		run_frontend $(($RANDOM % 3 + 1))
		sleep 2
	done
fi


