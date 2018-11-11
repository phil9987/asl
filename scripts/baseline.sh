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
createDirectory $logFolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	cliLogFolder="$logFolder/memtierCli$c"
	createDirectory $logFolder
	for run in $(seq 1 ${RESPETITIONS}); do
		log "Starting run $run / ${REPETITIONS}"
		numThreads=2
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT3DESIGNATOR} ${numThreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT2DESIGNATOR} ${numThreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${FIRSTMEMTIER}
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run ${runLogFolder}"
		createDirectory ${runLogFolder}
		collectLogsFromServer1 ${runLogFolder}
		collectLogsFromClient1 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient2 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient3 ${runLogFolder} ${FIRSTMEMTIER}
	done
done 
#
#
# 2.1 b) Write only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "Starting experiment for section 2.1b)"
logFolder="$LOGBASEFOLDER/logSection2_1b"
createDirectory $logFolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	cliLogFolder="$logFolder/memtierCli$c"
	createDirectory $logFolder
	for run in $(seq 1 ${RESPETITIONS}); do
		log "Starting run $run / ${REPETITIONS}"
		numThreads=2
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT3DESIGNATOR} ${numThreads} ${FIRSTMEMTIER} ${CLIENT3IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT2DESIGNATOR} ${numThreads} ${FIRSTMEMTIER} ${CLIENT2IP}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${FIRSTMEMTIER}
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run ${runLogFolder}"
		createDirectory ${runLogFolder}
		collectLogsFromServer1 ${runLogFolder}
		collectLogsFromClient1 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient2 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient3 ${runLogFolder} ${FIRSTMEMTIER}
	done
done 
#
# 2.2a) Read only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32
log "Starting experiment for section 2.2a)"
logFolder="$LOGBASEFOLDER/logSection2_2a"
createDirectory $logFolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.2a)"
	cliLogFolder="$logFolder/memtierCli$c"
	createDirectory $logFolder
	for run in $(seq 1 ${RESPETITIONS}); do
		log "Starting run $run / ${REPETITIONS}"
		numThreads=1
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${READONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${FIRSTMEMTIER}
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run ${runLogFolder}"
		createDirectory ${runLogFolder}
		collectLogsFromServer1 ${runLogFolder}
		collectLogsFromClient1 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient1 ${runLogFolder} ${SECONDMEMTIER}
	done
done 
#
# 2.2b) Write only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32
log "Starting experiment for section 2.2b)"
logFolder="$LOGBASEFOLDER/logSection2_2b"
createDirectory $logFolder
#define parameter ranges
memtierClients=(1 32)
#
for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.2b)"
	cliLogFolder="$logFolder/memtierCli$c"
	createDirectory $logFolder
	for run in $(seq 1 ${RESPETITIONS}); do
		log "Starting run $run / ${REPETITIONS}"
		numThreads=1
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${SECONDMEMTIER}
		runMemtierClient ${SERVER1IP} ${MEMCACHEDPORT} $c ${WRITEONLY} ${CLIENT1DESIGNATOR} ${numThreads} ${FIRSTMEMTIER}
		runLogFolder="$cliLogFolder/run$run"
		log "Creating folder for run ${runLogFolder}"
		createDirectory ${runLogFolder}
		collectLogsFromServer1 ${runLogFolder}
		collectLogsFromClient1 ${runLogFolder} ${FIRSTMEMTIER}
		collectLogsFromClient1 ${runLogFolder} ${SECONDMEMTIER}
	done
done 