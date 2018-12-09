#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh

# 2.2a) Read only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2a)"
logfolder="$LOGBASEFOLDER/logSection2_2a"
createDirectory $logfolder
#define parameter ranges
memtierclients=(4 12)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierClients=$c for section 2.2a)"
	clientlogfolder="$logfolder/memtierCli$c"
	createDirectory $clientlogfolder
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		memtierthreads=1
		startDstatClient1
		startDstatServer1
		startDstatServer2
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT1IP} ${SERVER2IP} ${CLIENT1DESIGNATOR} ${SERVER2DESIGNATOR}

		runMemtierClientLocal ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${SERVER2IP} ${MEMCACHEDPORT}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		stopAllClient1
		stopDstatServer1
		stopDstatServer2
		sleep 5

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromServer2 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder}
	done
done 
#
# 2.2b) Write only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2b)"
logfolder="$LOGBASEFOLDER/logSection2_2b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(3 4 5 6)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierClients=$c for section 2.2b)"
	clientlogfolder="$logfolder/memtierCli$c"
	createDirectory $clientlogfolder
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		memtierthreads=1
		startDstatClient1
		startDstatServer1
		startDstatServer2
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT1IP} ${SERVER2IP} ${CLIENT1DESIGNATOR} ${SERVER2DESIGNATOR}

		runMemtierClientLocal ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${SERVER2IP} ${MEMCACHEDPORT}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		stopAllClient1
		stopDstatServer1
		stopDstatServer2
		sleep 5

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromServer2 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder}
	done
done 