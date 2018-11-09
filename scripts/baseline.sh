#!/bin/bash
#Run this script from the first memtier client
#Make sure helper.sh is in the same directory
source helperFunctions.sh
source variables.sh
# initialize systems
startMemcachedServers
initMemcachedServers
logBaseFolder="experiments_$(date '+%d-%m-%Y_%H-%M-%S')"
log "Creating folder for logfiles: $logBaseFolder"
mkdir logBaseFolder
#
# 2.1 a) Read only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
log "Starting experiment for section 2.1a)"
logExp21aFolder="$logBaseFolder/logSection2_1a"
mkdir $logExp21aFolder
#define parameter ranges
memtierClients=(1 16 32)


for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	logExp21aFolder="$logExp21aFolder/memtierCli$c"
	mkdir $logExp21aFolder
	for run in {1..${REPETITIONS}}; do
		log "Starting run $run / ${REPETITIONS}"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT3IP}
		log "client3 started"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT2IP}
		log "client2 started"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT1DESIGNATOR}
		log "client1 started"
		logExp21aFolder="$logExp21aFolder/run$run"
		log "Creating folder for run $logExp21aFolder"
		mkdir $logExp21aFolder
		collectLogsFromServer1 $logExp21aFolder
		collectLogsFromClient1 $logExp21aFolder
		collectLogsFromClient2 $logExp21aFolder
		collectLogsFromClient3 $logExp21aFolder
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
# 3.1a) Read only, 1 middleware, 3 memtier clients with 2 thread each, 1 memcached server
# virtual clients per memtier client 1..32
# worker threads per middleware 8, 16, 32, 64
log "Starting experiment for section 3.1a)"
logExp31aFolder="$logBaseFolder/logSection3_1a"
mkdir $logExp31aFolder
#define parameter ranges
memtierClients=(1 32 64)

for c in "${memtierClients[@]}"; do
	log "Starting configuration memtierClients=$c for section 2.1a)"
	logExp31aFolder="$logExp31aFolder/memtierCli$c"
	for run in {1..${REPETITIONS}}; do
		log "Starting run $run / ${REPETITIONS}"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT3IP}
		log "client3 started"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT2DESIGNATOR} ${CLIENT2IP}
		log "client2 started"
		runMemtierClient ${SERVER1IP} $c ${READONLY} ${CLIENT1DESIGNATOR}
		log "client1 started"
		logExp31aFolder="$logExp31aFolder/run$run"
		log "Creating folder for run $logExp31aFolder"
		mkdir $logExp31aFolder
		collectLogsFromServer1 $logExp31aFolder
		collectLogsFromClient1 $logExp31aFolder
		collectLogsFromClient2 $logExp31aFolder
		collectLogsFromClient3 $logExp31aFolder
		collectLogsFromMiddleware1 $logExp31aFolder
	done
done 