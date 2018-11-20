#!/bin/bash
#Make sure variables.sh is in the same directory
source variables.sh

killScreen() {
    #args
    # $1: ip
    log "killing all screen sessions of $1"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "killall screen"
}

stopAllMW1() {
    ssh -o StrictHostKeyChecking=no junkerp@${MW1IP} "killall screen; cnt=0; while [[ ! -f ~/asl/logs/done.info && \${cnt} -lt 50 ]]; do cnt=\$((cnt + 1)); sleep 0.1; done; rm ~/asl/logs/done.info;"
    log "Middleware 1 stopped"
}

stopAllMW2() {
    ssh -o StrictHostKeyChecking=no junkerp@${MW2IP} "killall screen; cnt=0; while [[ ! -f ~/asl/logs/done.info && \${cnt} -lt 50 ]]; do cnt=\$((cnt + 1)); sleep 0.1; done; rm ~/asl/logs/done.info;"
    log "Middleware 2 stopped"
}

stopAllClient1() {
    # local client
    killall screen
}

stopAllClient2() {
    killScreen ${CLIENT2IP}
}

stopAllClient3() {
    killScreen ${CLIENT3IP}
}

# logs argument string to file
log () {
    #args
    # $1: The string which should be written to the logfile
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "$dt $1" >> experiment.log
}

startDstat() {
    #args
    # $1: ip
    # $2: designator
    designatordstat="$2${DSTATDESIGNATOR}"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "screen -dm -S ${designatordstat} dstat -clmn --noheaders --output ${DSTATFILE}"
}

startDstatMW1() {
    startDstat ${MW1IP} ${MW1DESIGNATOR}
}

startDstatMW2() {
    startDstat ${MW2IP} ${MW2DESIGNATOR}
}

startDstatClient1() {
    designatordstat="${CLIENT1DESIGNATOR}${DSTATDESIGNATOR}"
    screen -dm -S ${designatordstat} dstat -clmn --noheaders --output ${DSTATFILE}
}

startDstatClient2() {
    startDstat ${CLIENT2IP} ${CLIENT2DESIGNATOR}
}

startDstatClient3() {
    startDstat ${CLIENT3IP} ${CLIENT3DESIGNATOR}
}

startDstatServer1() {
    startDstat ${SERVER1IP} ${SERVER1DESIGNATOR}
}

startDstatServer2() {
    startDstat ${SERVER2IP} ${SERVER2DESIGNATOR}
}

startDstatServer3() {
    startDstat ${SERVER3IP} ${SERVER3DESIGNATOR}
}

startPing() {
    #args
    # $1: ip from
    # $2: ip to ping
    # $3: designator origin
    # $4: designator destination
    designator=$3$4
    designatorping="${designator}${PINGDESIGNATOR}"
    log "Starting ping with screen session ${designatorping}, writing to file ${designator}${PINGFILE}"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "screen -dm -S ${designatorping} bash -c 'ping -nD $2 &> ${PINGFILE}${designator}'"
}

# moves experiment.log to destination path
moveExperimentLog() {
    #args
    # $1: destination path
    echo "moving experiment.log to $1"
    mv experiment.log $1/experiment.log
}

# creates a directory with name arg1
createDirectory() {
    #args
    # $1: the name of the new directory
    mkdir -p $1
}

createRemoteDirectory() {
    ssh -o StrictHostKeyChecking=no junkerp@$1 "mkdir -p $2"
}

# removes a file from a remote server
removeFile() {
    #args
    # $1: ip
    # $2: file
    echo "deleting file $2 from $1"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "rm $2"
}

collectLogs() {
    #args
    # $1: path to copy logfiles to
    # $2: ip
    # $3: designator
    echo "Collecting logs from $3 ($2, $1)"
    dir="$1/$3"
    createDirectory ${dir}
    scp -o StrictHostKeyChecking=no junkerp@$2:~/asl/logs/* ${dir}
    ssh -o StrictHostKeyChecking=no junkerp@$2 "rm -r ~/asl/logs; mkdir -p ~/asl/logs"
}

# collects all relevant logs from MW1
collectLogsFromMiddleware1() {
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${MW1IP} ${MW1DESIGNATOR}
}

# collects all relevant logs from MW2
collectLogsFromMiddleware2() {
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${MW2IP} ${MW2DESIGNATOR}
}

# collects all relevant logs from SERVER1
collectLogsFromServer1(){
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${SERVER1IP} ${SERVER1DESIGNATOR}
}

# collects all relevant logs from SERVER2
collectLogsFromServer2(){
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${SERVER2IP} ${SERVER2DESIGNATOR}
}

# collects all relevant logs from SERVER3
collectLogsFromServer3(){
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${SERVER3IP} ${SERVER3DESIGNATOR}
}

# collects the logfiles from client1 (client from which script is executed)
collectLogsFromClient1() {
    # This client is the one running the commands, hence it is local
    #args
    # $1: path to copy the logfiles to
    echo "Collecting logs from ${CLIENT1DESIGNATOR} (local, $1)"
    dir="$1/${CLIENT1DESIGNATOR}"
    createDirectory ${dir}
    mv ~/asl/logs/* ${dir}
}

# collects all relevant logs from CLIENT2
collectLogsFromClient2() {
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${CLIENT2IP} ${CLIENT2DESIGNATOR}
}

# collects all relevant logs from CLIENT3
collectLogsFromClient3() {
    #args
    # $1: path to copy the logfiles to
    collectLogs $1 ${CLIENT3IP} ${CLIENT3DESIGNATOR}
}

# Starts all 3 servers
startMemcachedServers() {    
    # Setup, start memcached servers, fill them with data
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER1IP} "screen -L -dm -S ${SERVER1DESIGNATOR} memcached -p ${MEMCACHEDPORT}"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER2IP} "screen -L -dm -S ${SERVER2DESIGNATOR} memcached -p ${MEMCACHEDPORT}"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER3IP} "screen -L -dm -S ${SERVER3DESIGNATOR} memcached -p ${MEMCACHEDPORT}"
    log "Started memcached servers.. sleeping for 2s"
    sleep 2s
}

initMemcachedServers() {
    # start middleware1, connected to all 3 servers
    log "Function initMemcachedServers() entered"
    log "starting both middlewares once to avoid first startup problem..."
    echo "starting both middlewares quickly"
    logname="../logs/client1_init"
    startMiddleware1 3 1 ${NONSHARDED}
    startMiddleware2 3 1 ${NONSHARDED}
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=10 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
    memtier_benchmark --server=${MW2IP} --port=${MWPORT} --clients=1 --requests=10 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
    sleep 5
    stopAllMW1
    stopAllMW2
    echo "now initializing servers"
    log "Now initializing servers"
    startMiddleware1 3 1 ${NONSHARDED}
    # initialize memcached servers with all keys
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
    log "servers with values initialized"
    stopAllMW1
    initfolder="${LOGBASEFOLDER}/init"
    collectLogsFromMiddleware1 ${initfolder}
    collectLogsFromMiddleware2 ${initfolder}
    collectLogsFromClient1 ${initfolder}
}

# stops all 3 memcached servers and deletes the screenlog.0 file
stopMemcachedServers() {
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER1IP} "screen -X -S ${SERVER1DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER2IP} "screen -X -S ${SERVER2DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER3IP} "screen -X -S ${SERVER3DESIGNATOR} quit"
    removeFile ${SERVER1IP} "~/screenlog.0"
    removeFile ${SERVER2IP} "~/screenlog.0"
    removeFile ${SERVER3IP} "~/screenlog.0"
}

runMemtierClientLocal() {
    #args: 
    # $1: ip to connect to
    # $2: port to connect to
    # $3: numclients
    # $4: ratio e.g. ${READONLY}
    # $5: designator e.g. "client1"
    # $6: numthreads e.g. 2
    # $7: OPTIONAL ip2 to connect to
    # $8: OPTIONAL port2 to connect to
    logname=$5${FIRSTMEMTIER}
    log "memtier parameters ip=$1 port=$2 numclients=$3 ratio=$4 designator=$5 numthreads=$6 logname=${logname}"
    basecmd="memtier_benchmark --server=$1 --port=$2 --clients=$3 --test-time=${TESTTIME} --ratio=$4 --protocol=memcache_text --run-count=1 --threads=$6 --key-maximum=10000 --data-size=4096 --client-stats=../logs/${logname}clientstats --json-out-file=../logs/${logname}.json"
    if [[ $# -eq 6 ]]; then
        log "starting 1 memtier instance on $5 (local, $7, blockingmode)"
        log "executing $basecmd"
        $basecmd
    elif [[ $# -eq 8 ]]; then
        log "starting 2 memtier instances on $5 (local, $7:$8, nonblocking & blocking)"
        logname2=$5${SECONDMEMTIER}
        basecmd2="memtier_benchmark --server=$7 --port=$8 --clients=$3 --test-time=${TESTTIME} --ratio=$4 --protocol=memcache_text --run-count=1 --threads=$6 --key-maximum=10000 --data-size=4096 --client-stats=../logs/${logname2}clientstats --json-out-file=../logs/${logname2}.json"
        cmd1="screen -dm -S ${logname} ${basecmd}"
        log "executing $cmd1"
        $cmd1
        log "executing $basecmd2"
        $basecmd2
    else
        log "ERROR: invalid number of arguments (expected 6 for 1 memtier instance and 8 for two instances): $#"
    fi
}

# 
runMemtierClient() {
    #args: 
    # $1: ip to connect to
    # $2: port to connect to
    # $3: numclients
    # $4: ratio e.g. ${READONLY}
    # $5: designator e.g. "client1"
    # $6: numthreads e.g. 2
    # $7: client_IP
    # $8: OPTIONAL client_IP OR ip2 to connect to
    # $9: OPTIONAL port2 to connect to
    logname=$5${FIRSTMEMTIER}
    log "memtier parameters ip=$1 port=$2 numclients=$3 ratio=$4 designator=$5 numthreads=$6 logname=${logname}"
    basecmd="memtier_benchmark --server=$1 --port=$2 --clients=$3 --test-time=${TESTTIME} --ratio=$4 --protocol=memcache_text --run-count=1 --threads=$6 --key-maximum=10000 --data-size=4096 --client-stats=asl/logs/${logname}clientstats --json-out-file=asl/logs/${logname}.json"
    if [[ $# -eq 7 ]]; then
        log "starting 1 memtier instance on $5 (remote, $7, clientIP=$8)"
        ssh -o StrictHostKeyChecking=no junkerp@$7 "screen -dm -S ${logname} ${basecmd}"
    elif [[ $# -eq 9 ]]; then
        log "starting 2 memtier instances on $5 (remote, $7, clientIP=$8)"
        logname2=$5${SECONDMEMTIER}
        basecmd2="memtier_benchmark --server=$8 --port=$9 --clients=$3 --test-time=${TESTTIME} --ratio=$4 --protocol=memcache_text --run-count=1 --threads=$6 --key-maximum=10000 --data-size=4096 --client-stats=asl/logs/${logname2}clientstats --json-out-file=asl/logs/${logname2}.json"
        ssh -o StrictHostKeyChecking=no junkerp@$7 "screen -dm -S ${logname} ${basecmd}; screen -dm -S ${logname2} ${basecmd2}"
    else
        log "ERROR: invalid number of arguments (expected 7 for 1 memtier instance and 9 for two instances): $#"
    fi
}

# starts the middleware
startMiddleware() {
    #args:
    # $1: middleware_IP 
    # $2: designator e.g. "middleware1"
    # $3: numservers
    # $4: numWorkerThreads
    # $5: sharded
    log "Starting $2 with $3 servers (ip=$1)"
    basecmd="cd asl; screen -dm -S $2 java -jar dist/middleware-junkerp.jar -l $1 -p ${MWPORT} -t $4 -s $5 -m ${SERVER1IP}:${MEMCACHEDPORT}"
    log "${basecmd}"
    if [[ $3 -eq 1 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@$1 "${basecmd}"
    elif [[ $3 -eq 2 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@$1 "${basecmd} ${SERVER2IP}:${MEMCACHEDPORT}"
    elif [[ $3 -eq 3 ]]; then
        thiscmd="${basecmd} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
        ssh -o StrictHostKeyChecking=no junkerp@$1 ${thiscmd}
    else
        log "ERROR: cannot start middleware. Invalid parameter for numservers: $3"
    fi
    sleep 5
    log "Middleware started"
}

# starts MW1 with numservers
startMiddleware1() {
    #args
    # $1: numservers
    # $2: numWorkerThreads
    # $3: sharded
    startMiddleware ${MW1IP} ${MW1DESIGNATOR} $1 $2 $3
}

startMiddleware2() {
    #args
    # $1: numservers
    # $2: numWorkerThreads
    # $3: sharded
    startMiddleware ${MW2IP} ${MW2DESIGNATOR} $1 $2 $3
}

stopDstat() {
    #args
    # $1: ip
    # $2: designator
    designatordstat="$2${DSTATDESIGNATOR}"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "screen -X -S ${designatordstat} quit"
}

stopDstatServer1() {
    stopDstat ${SERVER1IP} ${SERVER1DESIGNATOR}
}

stopDstatServer2() {
    stopDstat ${SERVER2IP} ${SERVER2DESIGNATOR}
}

stopDstatServer3() {
    stopDstat ${SERVER3IP} ${SERVER3DESIGNATOR}
}