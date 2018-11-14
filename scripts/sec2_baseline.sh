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
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierclients=$c for section 2.1a)"
	clientlogfolder="${logfolder}/memtierCli$c"
	createDirectory ${clientlogfolder}
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		numthreads=2
		startDstatServer1
		startDstatClient1
		startDstatClient2
		startDstatClient3
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT2IP} ${SERVER1IP} ${CLIENT2DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT3IP} ${SERVER1IP} ${CLIENT3DESIGNATOR} ${SERVER1DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
		collectLogsFromClient2 ${runlogfolder} ${FIRSTMEMTIER}
		collectLogsFromClient3 ${runlogfolder} ${FIRSTMEMTIER}
		stopDstatAndCopyFileServer1 ${runlogfolder}
		stopDstatAndCopyFileClient1 ${runlogfolder}
		stopDstatAndCopyFileClient2 ${runlogfolder}
		stopDstatAndCopyFileClient3 ${runlogfolder}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER1DESIGNATOR}
		stopPingAndCopyFileClient2 ${runlogfolder} ${SERVER1DESIGNATOR}
		stopPingAndCopyFileClient3 ${runlogfolder} ${SERVER1DESIGNATOR}
	done
done 
#
#
# 2.1 b) Write only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.1b)"
logfolder="$LOGBASEFOLDER/logSection2_1b"
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
#
for c in "${memtierclients[@]}"; do
	log "## Starting configuration memtierclients=$c for section 2.1b)"
	clientlogfolder="${logfolder}/memtierCli$c"
	createDirectory ${clientlogfolder}
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		numthreads=2
		startDstatServer1
		startDstatClient1
		startDstatClient2
		startDstatClient3
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT2IP} ${SERVER1IP} ${CLIENT2DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT3IP} ${SERVER1IP} ${CLIENT3DESIGNATOR} ${SERVER1DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}

		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
		collectLogsFromClient2 ${runlogfolder} ${FIRSTMEMTIER}
		collectLogsFromClient3 ${runlogfolder} ${FIRSTMEMTIER}
		stopDstatAndCopyFileServer1 ${runlogfolder}
		stopDstatAndCopyFileClient1 ${runlogfolder}
		stopDstatAndCopyFileClient2 ${runlogfolder}
		stopDstatAndCopyFileClient3 ${runlogfolder}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER1DESIGNATOR} 
		stopPingAndCopyFileClient2 ${runlogfolder} ${SERVER1DESIGNATOR} 
		stopPingAndCopyFileClient3 ${runlogfolder} ${SERVER1DESIGNATOR}
	done
done 
#
# 2.2a) Read only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2a)"
logfolder="$LOGBASEFOLDER/logSection2_2a"
createDirectory $logfolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "## Starting configuration memtierClients=$c for section 2.2a)"
	clientlogfolder="$logfolder/memtierCli$c"
	createDirectory $clientlogfolder
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		numthreads=1
		startDstatClient1
		startDstatServer1
		startDstatServer2
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT1IP} ${SERVER2IP} ${CLIENT1DESIGNATOR} ${SERVER2DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
		stopDstatAndCopyFileServer1 ${runlogfolder}
		stopDstatAndCopyFileServer2 ${runlogfolder}
		stopDstatAndCopyFileClient1 ${runlogfolder}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER1DESIGNATOR}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER2DESIGNATOR}
	done
done 
#
# 2.2b) Write only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2b)"
logfolder="$LOGBASEFOLDER/logSection2_2b"
createDirectory $logfolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "## Starting configuration memtierClients=$c for section 2.2b)"
	clientlogfolder="$logfolder/memtierCli$c"
	createDirectory $clientlogfolder
	for run in $(seq 1 ${REPETITIONS}); do
		log "# Starting run ${run} / ${REPETITIONS}"
		numthreads=1
		startDstatClient1
		startDstatServer1
		startDstatServer2
		startPing ${CLIENT1IP} ${SERVER1IP} ${CLIENT1DESIGNATOR} ${SERVER1DESIGNATOR}
		startPing ${CLIENT1IP} ${SERVER2IP} ${CLIENT1DESIGNATOR} ${SERVER2DESIGNATOR}

		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
		
		runlogfolder="${clientlogfolder}/run${run}"
		log "Creating folder for run ${runlogfolder}"
		createDirectory ${runlogfolder}
		collectLogsFromServer1 ${runlogfolder}
		collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
		stopDstatAndCopyFileServer1 ${runlogfolder}
		stopDstatAndCopyFileServer2 ${runlogfolder}
		stopDstatAndCopyFileClient1 ${runlogfolder}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER1DESIGNATOR}
		stopPingAndCopyFileClient1 ${runlogfolder} ${SERVER2DESIGNATOR}
	done
done 