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
createDirectory $logfolder
#define parameter ranges
memtierclients=(32)
workerthreads=(1 8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.1a)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=2
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
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER}
			stopAllMW1
			stopAllClient1
			stopAllClient2
			stopAllClient3
			stopDstatServer1
			sleep 5

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 
#
log "### Starting experiment for section 3.1b)"
logfolder="$LOGBASEFOLDER/logSection3_1b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(32)
workerthreads=(1 8 64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.1b)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=2
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
			log "ARGUMENTS PASSED> ip=${MW1IP} port=${MWPORT} numclients=$c ratio=${WRITEONLY} designator=${CLIENT3DESIGNATOR} numthreads=${memtierthreads} instance=${FIRSTMEMTIER} clientIP=${CLIENT3IP}"
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${FIRSTMEMTIER} ${CLIENT2IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreadsnu} ${FIRSTMEMTIER}
			stopAllMW1
			stopAllClient1
			stopAllClient2
			stopAllClient3
			stopDstatServer1
			sleep 5

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 
#