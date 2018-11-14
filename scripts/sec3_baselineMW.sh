#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 3.1a) Read only, 1 middleware, 3 memtier clients with 2 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.1a)"
logfolder="$LOGBASEFOLDER/logSection3_1a"
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
workerthreads=(8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.1a)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			numthreads=2
			startDstatServer1
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}

			startMiddleware1 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
			stopMiddleware1

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
			stopDstatAndCopyFileMW1 ${runlogfolder}
			stopPingAndCopyFileClient1 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient2 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient3 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileMW1 ${runlogfolder} ${SERVER1DESIGNATOR}
		done
	done
done 
#
# 3.1b) Write only, 1 middleware, 3 memtier clients with 2 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.1b)"
logfolder="$LOGBASEFOLDER/logSection3_1b"
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
workerthreads=(8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.1b)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			numthreads=2
			startDstatServer1
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}

			startMiddleware1 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
			stopMiddleware1

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
			stopDstatAndCopyFileMW1 ${runlogfolder}
			stopPingAndCopyFileClient1 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient2 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient3 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileMW1 ${runlogfolder} ${SERVER1DESIGNATOR}
		done
	done
done 
#
# 3.2a) Read only, 2 middleware, 3 client vms with 2 memtier instance with 1 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.2a)"
logfolder="$LOGBASEFOLDER/logSection3_2a"
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
workerthreads=(8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.2a)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			numthreads=1
			startDstatServer1
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startDstatMW2
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW2IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}


			startMiddleware1 1 ${w} ${NONSHARDED}
			startMiddleware2 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${SECONDMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${SECONDMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${SECONDMEMTIER}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
			stopMiddleware1
			stopMiddleware2

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient1 ${runlogfolder} ${SECONDMEMTIER}
			collectLogsFromClient2 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient2 ${runlogfolder} ${SECONDMEMTIER}
			collectLogsFromClient3 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient3 ${runlogfolder} ${SECONDMEMTIER}
			stopDstatAndCopyFileServer1 ${runlogfolder}
			stopDstatAndCopyFileClient1 ${runlogfolder}
			stopDstatAndCopyFileClient2 ${runlogfolder}
			stopDstatAndCopyFileClient3 ${runlogfolder}
			stopDstatAndCopyFileMW1 ${runlogfolder}
			stopDstatAndCopyFileMW2 ${runlogfolder}
			stopPingAndCopyFileClient1 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient2 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient3 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileMW1 ${runlogfolder} ${SERVER1DESIGNATOR}
			stopPingAndCopyFileMW2 ${runlogfolder} ${SERVER1DESIGNATOR}
		done
	done
done 
#
# 3.2b) Write only, 2 middleware, 3 client vms with 2 memtier instance with 1 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.2b)"
logfolder="$LOGBASEFOLDER/logSection3_2b"
createdirectory $logfolder
#define parameter ranges
memtierclients=(1 32)
workerthreads=(8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.2b)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			numthreads=1
			startDstatServer1
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startDstatMW2
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW2IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}


			startMiddleware1 1 ${w} ${NONSHARDED}
			startMiddleware2 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${numthreads} ${SECONDMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${numthreads} ${SECONDMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${SECONDMEMTIER}
			runMemtierClient ${MW2IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numthreads} ${FIRSTMEMTIER}
			stopMiddleware1
			stopMiddleware2

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient1 ${runlogfolder} ${SECONDMEMTIER}
			collectLogsFromClient2 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient2 ${runlogfolder} ${SECONDMEMTIER}
			collectLogsFromClient3 ${runlogfolder} ${FIRSTMEMTIER}
			collectLogsFromClient3 ${runlogfolder} ${SECONDMEMTIER}
			stopDstatAndCopyFileServer1 ${runlogfolder}
			stopDstatAndCopyFileClient1 ${runlogfolder}
			stopDstatAndCopyFileClient2 ${runlogfolder}
			stopDstatAndCopyFileClient3 ${runlogfolder}
			stopDstatAndCopyFileMW1 ${runlogfolder}
			stopDstatAndCopyFileMW2 ${runlogfolder}
			stopPingAndCopyFileClient1 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient2 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileClient3 ${runlogfolder} ${MW1DESIGNATOR}
			stopPingAndCopyFileMW1 ${runlogfolder} ${SERVER1DESIGNATOR}
			stopPingAndCopyFileMW2 ${runlogfolder} ${SERVER1DESIGNATOR}
		done
	done
done 