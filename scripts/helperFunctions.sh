#!/bin/bash
#Make sure variables.sh is in the same directory
source variables.sh

killScreen() {
    #args
    # $1: ip
    ip=$1
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "killall screen"
}

stopAllMW1() {
    killScreen ${MW1IP}
    sleep 5
}

stopAllMW2() {
    killScreen ${MW2IP}
    sleep 5
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
    ip=$1
    designator=$2
    designatordstat="${designator}${DSTATDESIGNATOR}"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -dm -S ${designatordstat} dstat -clmn --noheaders --output ${DSTATFILE}"
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
    ip=$1
    iptoping=$2
    designator=$3$4
    designatorping="${designator}${PINGDESIGNATOR}"
    log "Starting ping with screen session ${designatorping}, writing to file ${designator}${PINGFILE}"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -dm -S ${designatorping} bash -c 'ping -nD ${iptoping} &> ${PINGFILE}${designator}'"
}

# moves experiment.log to destination path
moveExperimentLog() {
    #args
    # $1: destination path
    destpath=$1
    echo "moving experiment.log to ${destpath}"
    mv experiment.log ${destpath}/experiment.log
}

# creates a directory with name arg1
createDirectory() {
    #args
    # $1: the name of the new directory
    dir=$1
    mkdir -p ${dir}
}

createRemoteDirectory() {
    ip=$1
    dir=$2
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "mkdir -p ${dir}"
}

# removes a file from a remote server
removeFile() {
    #args
    # $1: ip
    # $2: file
    ip=$1
    file=$2
    echo "deleting file ${file} from ${ip}"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "rm ${file}"
}

collectLogs() {
    #args
    # $1: path to copy logfiles to
    # $2: ip
    # $3: designator
    path=$1
    ip=$2
    designator=$3
    echo "Collecting logs from ${designator} ($ip, $path)"
    dir="${path}/${designator}"
    createDirectory dir
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/* dir
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "rm -r ~/asl/logs; mkdir -p ~/asl/logs"
}

# collects all relevant logs from MW1
collectLogsFromMiddleware1() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${MW1IP} ${MW1DESIGNATOR}
}

# collects all relevant logs from MW2
collectLogsFromMiddleware2() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${MW2IP} ${MW2DESIGNATOR}
}

# collects all relevant logs from SERVER1
collectLogsFromServer1(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${SERVER1IP} ${SERVER1DESIGNATOR}
}

# collects all relevant logs from SERVER2
collectLogsFromServer2(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${SERVER2IP} ${SERVER2DESIGNATOR}
}

# collects all relevant logs from SERVER3
collectLogsFromServer3(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${SERVER3IP} ${SERVER3DESIGNATOR}
}

# collects the logfiles from client1 (client from which script is executed)
collectLogsFromClient1() {
    # This client is the one running the commands, hence it is local
    #args
    # $1: path to copy the logfiles to
    path=$1
    echo "Collecting logs from ${CLIENT1DESIGNATOR} (local, ${path})"
    dir="${path}/${CLIENT1DESIGNATOR}"
    createDirectory dir
    mv ~/asl/logs/* dir
}

# collects all relevant logs from CLIENT2
collectLogsFromClient2() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${CLIENT2IP} ${CLIENT2DESIGNATOR}
}

# collects all relevant logs from CLIENT3
collectLogsFromClient3() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogs ${path} ${CLIENT3IP} ${CLIENT3DESIGNATOR}
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
    startMiddleware1 3 1 ${NONSHARDED}
    # initialize memcached servers with all keys
    logname="client1_init"
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=500 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=${logname}.log --json-out-file=${logname}.json
    log "servers with values initialized"
    stopAllMW1
    initfolder="${LOGBASEFOLDER}/init"
    collectLogsFromMiddleware1 initfolder
    collectLogsFromClient1 initfolder
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

# 
runMemtierClient() {
    #args: 
    # $1: ip to connect to
    # $2: port to connect to
    # $3: numclients
    # $4: ratio e.g. ${READONLY}
    # $5: designator e.g. "client1"
    # $6: numthreads e.g. 2
    # $7: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    # $8: client_IP (if not locally executed)
    ip=$1
    port=$2
    numclients=$3
    ratio=$4
    designator=$5
    numthreads=$6
    instance=$7
    logname=${designator}${instance}
    basecmd="memtier_benchmark --server=${ip} --port=${port} --clients=${numclients} --test-time=${TESTTIME} --ratio=${ratio} --protocol=memcache_text --run-count=1 --threads=${numthreads} --key-maximum=10000  --data-size=4096 --out-file=${logname}.log --json-out-file=${logname}.json"
    if [[ $# -eq 7 ]]; then
        if [[ ${instance} == ${FIRSTMEMTIER} ]]; then
            log "starting memtier ${designator} (local, ${instance}, blockingmode) connected to ${ip}:${port} with clients=${numclients} threads=${numthreads} and a ratio of ${ratio} writing logs to screenlog.0"
            cmd="${basecmd}"
            log "$cmd"
            $cmd
        else
            log "starting memtier ${designator} (local, ${instance}) connected to ${ip}:${port} with clients=${numclients} threads=${numthreads} and a ratio of ${ratio} writing logs to screenlog.0"
            screen -dm -S ${logname} ${basecmd}
        fi
    elif [[ $# -eq 8 ]]; then
        clientIP=$8
        log "starting memtier ${designator} (remote, ${instance}) connected to ${ip}:${port} with clients=${numclients} threads=${numthreads} and a ratio of ${ratio} writing logs to screenlog.0"
        ssh -o StrictHostKeyChecking=no junkerp@${clientIP} "screen -dm -S ${logname} ${basecmd}"
    else
        log "ERROR: invalid number of arguments (expected 7 for local and 8 for remote client execution): $#"
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
    ip=$1
    designator=$2
    numservers=$3
    numthreads=$4
    sharded=$5
    log "Starting $designator with ${numservers} servers (ip=$ip)"
    if [[ ${numservers} -eq 1 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@${ip} "cd asl; screen -dm -S ${designator} java -jar dist/middleware-junkerp.jar  -l ${ip} -p ${MWPORT} -t ${numthreads} -s ${sharded} -m ${SERVER1IP}:${MEMCACHEDPORT}"
    elif [[ ${numservers} -eq 2 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@${ip} "cd asl; screen -dm -S ${designator} java -jar dist/middleware-junkerp.jar  -l ${ip} -p ${MWPORT} -t ${numthreads} -s ${sharded} -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT}"
    elif [[ ${numservers} -eq 3 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@${ip} "cd asl; screen -dm -S ${designator} java -jar dist/middleware-junkerp.jar  -l ${ip} -p ${MWPORT} -t ${numthreads} -s ${sharded} -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
    else
        log "ERROR: cannot start middleware. Invalid parameter for numservers: ${numservers}"
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
    numservers=$1
    numthreads=$2
    sharded=$3
    startMiddleware ${MW1IP} ${MW1DESIGNATOR} ${numservers} ${numthreads} ${sharded}
}

startMiddleware2() {
    #args
    # $1: numservers
    # $2: numWorkerThreads
    # $3: sharded
    numservers=$1
    numthreads=$2
    sharded=$3
    startMiddleware ${MW2IP} ${MW2DESIGNATOR} ${numservers} ${numthreads} ${sharded}
}

stopDstat() {
    #args
    # $1: ip
    # $2: designator
    ip=$1
    designator=$2
    designatordstat="${designator}${DSTATDESIGNATOR}"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -X -S ${designatordstat} quit"
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