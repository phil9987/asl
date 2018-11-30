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
memtierclients=(1 2 3 4 5 6 32)
workerthreads=(8 16 32 64 128)
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
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads}
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
# 3.1b) Write only, 1 middleware, 3 memtier clients with 2 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.1b)"
logfolder="$LOGBASEFOLDER/logSection3_1b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(1 3 6 12 20 32)
workerthreads=(8 16 32 64 128)
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
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads}
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
done #
# 3.2a) Read only, 2 middleware, 3 client vms with 2 memtier instance with 1 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.2a)"
logfolder="$LOGBASEFOLDER/logSection3_2a"
createDirectory $logfolder
#define parameter ranges
memtierclients=(1 2 3 4 5 6 32)
workerthreads=(8 16 32 64 128)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.2a)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=1
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
			startPing ${MW2IP} ${SERVER1IP} ${MW2DESIGNATOR} ${SERVER1DESIGNATOR}

			startMiddleware1 1 ${w} ${NONSHARDED}
			startMiddleware2 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
			stopAllMW1
			stopAllMW2
			stopAllClient1
			stopAllClient2
			stopAllClient3
			stopDstatServer1
			sleep 5

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromMiddleware2 ${runlogfolder}
		done
	done
done 
#
# 3.2b) Write only, 2 middleware, 3 client vms with 2 memtier instance with 1 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 3.2b)"
logfolder="$LOGBASEFOLDER/logSection3_2b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(1 3 6 12 20 32)
workerthreads=(8 16 32 64 128)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 3.2b)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=1
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
			startPing ${MW2IP} ${SERVER1IP} ${MW2DESIGNATOR} ${SERVER1DESIGNATOR}

			startMiddleware1 1 ${w} ${NONSHARDED}
			startMiddleware2 1 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
			stopAllMW1
			stopAllMW2
			stopAllClient1
			stopAllClient2
			stopAllClient3
			stopDstatServer1
			sleep 5

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromMiddleware2 ${runlogfolder}
		done
	done
done 
