#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 2.1 a) Read only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "Starting experiment for section 2.1a)"
logFolder="$LOGBASEFOLDER/logSection2_1a"
mkdir $logFolder
#define parameter ranges
memtierClients=(1 16 32)
#
for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	cliLogFolder="$logFolder/memtierCli$c"
	mkdir $logFolder
	for run in {1..${REPETITIONS}}; do
		log "Starting run $run / ${REPETITIONS}"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT1DESIGNATOR}
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run $runLogFolder"
		mkdir $runLogFolder
		collectLogsFromServer1 $runLogFolder
		collectLogsFromClient1 $runLogFolder
		collectLogsFromClient2 $runLogFolder
		collectLogsFromClient3 $runLogFolder
	done
done 
#
#
# 2.1 b) Write only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
#
# 2.2a) Read only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32
#
# 2.2b) Write only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32