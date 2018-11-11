#!/bin/bash

# TODO: fix runMemtierClient FIRST SECOND and PORT arguments are new


#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 3.1a) Read only, 1 middleware, 3 memtier clients with 2 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "Starting experiment for section 3.1a)"
logFolder="$LOGBASEFOLDER/logSection3_1a"
mkdir $logFolder
#define parameter ranges
memtierClients=(1 32 64)

for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	cliLogFolder="$logFolder/memtierCli$c"
	for run in {1..${REPETITIONS}}; do
		log "Starting run $run / ${REPETITIONS}"
		startMiddleware1 1
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR}
		stopMiddleware1
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run $runLogFolder"
		mkdir $runLogFolder
		collectLogsFromServer1 $runLogFolder
		collectLogsFromClient1 $runLogFolder
		collectLogsFromClient2 $runLogFolder
		collectLogsFromClient3 $runLogFolder
		collectLogsFromMiddleware1 $runLogFolder
	done
done 