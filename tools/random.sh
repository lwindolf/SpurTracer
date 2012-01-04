
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

		sleep 2
		
		steps=$(($RANDOM % 5 + 1))
		i=0
		while [ $i -lt $steps ];
		do
			i=$(($i + 1))
			sleep $(($RANDOM % 3 + 1))
			curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=running&desc=step $i/$steps"
		done

		sleep 2

		curl -s "$SERVER/set?host=$theHost&component=comp&time=$(date +%s)&type=n&ctxt=${ctxt}_${nr}&status=finished&desc=test+request+done"
		nr=$(($nr + 1))
	done
fi
