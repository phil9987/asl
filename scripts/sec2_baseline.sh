#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 2.1 a) Read only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.1a)"
logfolder="$LOGBASEFOLDER/logSection2_1a"
createDirectory $logfolder
#define parameter ranges
#memtierclients=(1 2 3 4 5 6 32)
memtierclients=(32)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierclients=$c for section 2.1a)"
	clientlogfolder="${logfolder}/memtierCli$c"
	createDirectory ${clientlogfolder}
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		memtierthreads=2
		startDstatServer1
		startDstatClient1
		startDstatClient2
		startDstatClient3
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT2IP} ${SERVER1IP} ${CLIENT2DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT3IP} ${SERVER1IP} ${CLIENT3DESIGNATOR} ${SERVER1DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		stopDstatServer1 ${runlogfolder}
		stopAllClient1
		stopAllClient2
		stopAllClient3
		sleep 5

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder}
		collectLogsFromClient2 ${runlogfolder}
		collectLogsFromClient3 ${runlogfolder}
	done
done 
#
#
# 2.1 b) Write only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.1b)"
logfolder="$LOGBASEFOLDER/logSection2_1b"
createDirectory $logfolder
#define parameter ranges
#memtierclients=(1 3 6 12 20 32 40)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierclients=$c for section 2.1b)"
	clientlogfolder="${logfolder}/memtierCli$c"
	createDirectory ${clientlogfolder}
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		memtierthreads=2
		startDstatServer1
		startDstatClient1
		startDstatClient2
		startDstatClient3
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT2IP} ${SERVER1IP} ${CLIENT2DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT3IP} ${SERVER1IP} ${CLIENT3DESIGNATOR} ${SERVER1DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		stopDstatServer1 ${runlogfolder}
		stopAllClient1
		stopAllClient2
		stopAllClient3
		sleep 5

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder}
		collectLogsFromClient2 ${runlogfolder}
		collectLogsFromClient3 ${runlogfolder}
	done
done #
# 2.2a) Read only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2a)"
logfolder="$LOGBASEFOLDER/logSection2_2a"
createDirectory $logfolder
#define parameter ranges
#memtierclients=(1 2 3 4 5 6 32)
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

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER}
		
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
#memtierclients=(1 3 6 12 20 32 40)
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

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER}
		
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