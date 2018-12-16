#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh

# 4) Write only, full system 2 middlewares, 2 memtier clients per vm with 1 thread each on 3 client vms, 3 memcached servers
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 4b)"
logfolder="$LOGBASEFOLDER/logSection4b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(40)
workerthreads=(64)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 4b)"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=1
			startDstatServer1
			startDstatServer2
			startDstatServer3
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startDstatMW2
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT1IP} ${MW2IP} ${CLIENT1DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT2IP} ${MW2IP} ${CLIENT2DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT3IP} ${MW2IP} ${CLIENT3DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW1IP} ${SERVER2IP} ${MW1DESIGNATOR} ${SERVER2DESIGNATOR}
			startPing ${MW1IP} ${SERVER3IP} ${MW1DESIGNATOR} ${SERVER3DESIGNATOR}
			startPing ${MW2IP} ${SERVER1IP} ${MW2DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW2IP} ${SERVER2IP} ${MW2DESIGNATOR} ${SERVER2DESIGNATOR}
			startPing ${MW2IP} ${SERVER3IP} ${MW2DESIGNATOR} ${SERVER3DESIGNATOR}


			startMiddleware1 3 ${w} ${NONSHARDED}
			startMiddleware2 3 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
			stopAllMW1
			stopAllMW2
			stopAllClient1
			stopAllClient2
			stopAllClient3
			stopDstatServer1
			stopDstatServer2
			stopDstatServer3
			sleep 5

			runlogfolder="${clientlogfolder}/run${run}"
			log "Creating folder for run ${runlogfolder}"
			createDirectory ${runlogfolder}
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromMiddleware2 ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromServer2 ${runlogfolder}
			collectLogsFromServer3 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 


#
# 2.2b) Write only, 2 memtier clients with 1 thread each running on one client vm, 2 memcached server
# virtual clients per memtier client 1..32
log "### Starting experiment for section 2.2b)"
logfolder="$LOGBASEFOLDER/logSection2_2b"
createDirectory $logfolder
#define parameter ranges
memtierclients=(40)
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