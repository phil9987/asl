#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
#
# 5c) Multigets, sharded, full system, each memtier instance has 1 thread and 2 virtual clients, the middleware has 64 worker threads (or max throughput amount of workerthreads)
# virtual clients per memtier client 2
# worker threads per middleware 64 ?
log "### Starting experiment for section 5c)"
logfolder="$LOGBASEFOLDER/logSection5c"
createDirectory $logfolder
#define parameter ranges
memtierclients=(2)
workerthreads=(64)
keys(1 9)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
	    for k in "${keys[@]}"; do
            log "## Starting configuration memtierclients=${c} workerthreads=${w} keys=${k} for section 5c)"
            clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}keys${k}"
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


                startMiddleware1 3 ${w} ${SHARDED}
                startMiddleware2 3 ${w} ${SHARDED}
                runMemtierClient ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
                runMemtierClient ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
                runMemtierClientLocal ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
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
done 

# 5d) Multigets, non-sharded, full system, each memtier instance has 1 thread and 2 virtual clients, the middleware has 64 worker threads (or max throughput amount of workerthreads)
# virtual clients per memtier client 2
# worker threads per middleware 64 ?
log "### Starting experiment for section 5d)"
logfolder="$LOGBASEFOLDER/logSection5d"
createDirectory $logfolder
#define parameter ranges
memtierclients=(2)
workerthreads=(64)
keys(1 9)
#
for c in "${memtierclients[@]}"; do
	for w in "${workerthreads[@]}"; do
	    for k in "${keys[@]}"; do
            log "## Starting configuration memtierclients=${c} workerthreads=${w} keys=${k} for section 5d)"
            clientlogfolder="${logfolder}/memtierCli${c}workerThreads${w}keys${k}"
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
                runMemtierClient ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT3DESIGNATOR} ${memtierthreads} ${CLIENT3IP} ${MW2IP} ${MWPORT}
                runMemtierClient ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT2DESIGNATOR} ${memtierthreads} ${CLIENT2IP} ${MW2IP} ${MWPORT}
                runMemtierClientLocal ${MW1IP} ${MWPORT} $c 1:${k} ${CLIENT1DESIGNATOR} ${memtierthreads} ${MW2IP} ${MWPORT}
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
done 