#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 6a) Read only, 1 memcached server, 1 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6a)"
logfolder="$LOGBASEFOLDER/logSection6a"
createDirectory $logfolder
#define parameter ranges
memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6a) 1server 1mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_1server_1mw"
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

# 6a) Read only, 3 memcached server, 1 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6a)"
logfolder="$LOGBASEFOLDER/logSection6a"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6a) 3server 1mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_3server_1mw"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=2
			startDstatServer1
			startDstatServer2
			startDstatServer3
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW1IP} ${SERVER2IP} ${MW1DESIGNATOR} ${SERVER2DESIGNATOR}


			startMiddleware1 3 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} 
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads}
			stopAllMW1
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
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromServer2 ${runlogfolder}
			collectLogsFromServer3 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 

# 6a) Read only, 1 memcached server, 2 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6a)"
logfolder="$LOGBASEFOLDER/logSection6a"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6a) 1server 2mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_1server_2mw"
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
			startPing ${CLIENT1IP} ${MW2IP} ${CLIENT1DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT2IP} ${MW2IP} ${CLIENT2DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT3IP} ${MW2IP} ${CLIENT3DESIGNATOR} ${MW2DESIGNATOR}
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
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromMiddleware2 ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 

# 6a) Read only, 3 memcached server, 2 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6a)"
logfolder="$LOGBASEFOLDER/logSection6a"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6a) 3server 2mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_3server_2mw"
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
			startPing ${MW2IP} ${SERVER1IP} ${MW2DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW2IP} ${SERVER2IP} ${MW2DESIGNATOR} ${SERVER2DESIGNATOR}


			startMiddleware1 3 ${w} ${NONSHARDED}
			startMiddleware2 3 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
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
# 6b) Write only, 1 memcached server, 1 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6b)"
logfolder="$LOGBASEFOLDER/logSection6b"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6b) 1server 1mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_1server_1mw"
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
done 

# 6b) Write only, 3 memcached server, 1 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6b)"
logfolder="$LOGBASEFOLDER/logSection6b"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6b) 3server 1mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_3server_1mw"
		createDirectory ${clientlogfolder}
		for run in $(seq 1 ${REPETITIONS}); do
			log "# Starting run ${run} / ${REPETITIONS}"
			memtierthreads=2
			startDstatServer1
			startDstatServer2
			startDstatServer3
			startDstatClient1
			startDstatClient2
			startDstatClient3
			startDstatMW1
			startPing ${CLIENT1IP} ${MW1IP} ${CLIENT1DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT2IP} ${MW1IP} ${CLIENT2DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${CLIENT3IP} ${MW1IP} ${CLIENT3DESIGNATOR} ${MW1DESIGNATOR}
			startPing ${MW1IP} ${SERVER1IP} ${MW1DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW1IP} ${SERVER2IP} ${MW1DESIGNATOR} ${SERVER2DESIGNATOR}


			startMiddleware1 3 ${w} ${NONSHARDED}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP}
			runMemtierClient ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} 
			runMemtierClientLocal ${MW1IP} ${MWPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${memtierthreads}
			stopAllMW1
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
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromServer2 ${runlogfolder}
			collectLogsFromServer3 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 

# 6b) Write only, 1 memcached server, 2 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6b)"
logfolder="$LOGBASEFOLDER/logSection6b"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6a) 1server 2mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_1server_2mw"
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
			startPing ${CLIENT1IP} ${MW2IP} ${CLIENT1DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT2IP} ${MW2IP} ${CLIENT2DESIGNATOR} ${MW2DESIGNATOR}
			startPing ${CLIENT3IP} ${MW2IP} ${CLIENT3DESIGNATOR} ${MW2DESIGNATOR}
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
			collectLogsFromMiddleware1 ${runlogfolder}
			collectLogsFromMiddleware2 ${runlogfolder}
			collectLogsFromServer1 ${runlogfolder}
			collectLogsFromClient1 ${runlogfolder}
			collectLogsFromClient2 ${runlogfolder}
			collectLogsFromClient3 ${runlogfolder}
		done
	done
done 

# 6b) Write only, 3 memcached server, 2 mw
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "### Starting experiment for section 6b)"
logfolder="$LOGBASEFOLDER/logSection6b"
createDirectory $logfolder
#define parameter ranges

memtierclients=(32)
workerthreads=(8 32)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
		log "## Starting configuration memtierclients=${c} workerthreads=${w} for section 6b) 3server 2mw"
		clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}_3server_2mw"
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
			startPing ${MW2IP} ${SERVER1IP} ${MW2DESIGNATOR} ${SERVER1DESIGNATOR}
			startPing ${MW2IP} ${SERVER2IP} ${MW2DESIGNATOR} ${SERVER2DESIGNATOR}


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