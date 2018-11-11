#!/bin/bash

. $PWD/variables.sh
# logs argument string to file
log () {
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "$dt $1" >> experiment.log
}

moveExperimentLog() {
    #args
    # $1: destination path
    echo "moving experiment.log to $1"
    mv experiment.log $1/experiment.log
}

createDirectory() {
    mkdir -p $1
}

removeFile() {
    #args
    # $1: ip
    # $2: file
    ip=$1
    file=$2
    echo "deleting file $file from $ip"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "rm ${file}"
}

collectLogsFromMiddleware() {
    #args
    # $1: path to copy the logfiles to
    # $2: middlewareip
    # $3: designator
    path=$1
    ip=$2
    designator=$3
    echo "Collecting logs from $designator ($ip, $path)"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/screenlog.0 ${path}/${designator}_screenlog0.log
    removeFile ${ip} "~/asl/screenlog.0"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/requests.log ${path}/${designator}_requests.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/error.log ${path}/${designator}_error.log
}

collectLogsFromMiddleware1() {
    #args
    # $1: path to copy the logfiles to
    collectLogsFromMiddleware $1 ${MW1IP} ${MW1DESIGNATOR}
}

collectLogsFromMiddleware2() {
    #args
    # $1: path to copy the logfiles to
    collectLogsFromMiddleware $1 ${MW2IP} ${MW2DESIGNATOR}
}

collectLogsFromServer() {
    #args
    # $1: path to copy the logfiles to
    # $2: serverip
    # $3: designator
    echo "Collecting logs from server $3 ($2, $1)"
    scp -o StrictHostKeyChecking=no junkerp@$2:~/screenlog.0 $1/$3_screenlog0.log
}

collectLogsFromServer1(){
    #args
    # $1: path to copy the logfiles to
    collectLogsFromServer $1 ${SERVER1IP} ${SERVER1DESIGNATOR}
}

collectLogsFromServer2(){
    #args
    # $1: path to copy the logfiles to
    collectLogsFromServer $1 ${SERVER2IP} ${SERVER2DESIGNATOR}
}

collectLogsFromServer3(){
    #args
    # $1: path to copy the logfiles to
    collectLogsFromServer $1 ${SERVER3IP} ${SERVER3DESIGNATOR}
}

collectLogsFromClient() {
    #args
    # $1: path to copy the logfiles to
    # $2: clientip
    # $3: designator
    destPath=$1
    ip=$2
    designator=$3
    echo "Collecting logs from $designator ($ip, $destPath)"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/screenlog.0 ${destPath}/${designator}_screenlog0.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/$3.log ${destPath}/${designator}.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/$3.json ${destPath}/${designator}.json
}

collectLogsFromClient1() {
    # This client is the one running the commands, hence it is local
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    destPath=$1
    instance=$2
    logname=${CLIENT1DESIGNATOR}${instance}
    echo "Collecting logs from $logname (local, $destpath)"
    if [[ ${instance} == ${FIRSTMEMTIER} ]]; then
        mv ${logname}_screenlog.0 ${destPath}/${logname}_screenlog0.log
        mv ${logname}.log ${destPath}/${logname}.log
        mv ${logname}.json ${destPath}/${logname}.json
    elif [[ ${instance} == ${SECONDMEMTIER} ]]; then
        mv screenlog.0 ${destPath}/${logname}_screenlog0.log
        mv ${logname}.log ${destPath}/${logname}.log
        mv ${logname}.json ${destPath}/${logname}.json
    else
        log "ERROR: invalid instance argument for collectLogsFromClient1: ${instance}"
    fi
}

collectLogsFromClient2() {
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    destPath=$1
    instance=$2
    logname=${CLIENT2DESIGNATOR}${instance}
    collectLogsFromClient ${destPath} ${CLIENT2IP} ${logname}
}

collectLogsFromClient3() {
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    destPath=$1
    instance=$2
    logname=${CLIENT3DESIGNATOR}${instance}
    collectLogsFromClient ${destPath} ${CLIENT3IP} ${logname}
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

waitForFile() {
    #args
    # $1: path to file we wait to be created
    while [[ ! -f "$logname.json" ]]; do
        :
    done
}

initMemcachedServers() {
    # start middleware1
    log "Function initMemcachedServers() entered"
    startMiddleware1 3
    log "Started middleware.. sleeping for 2s"
    sleep 2s
    # initialize memcached servers with all keys
    logname="client1_init"
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=10 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=$logname.log --json-out-file=$logname.json
    log "servers with values initialized"
    waitForFile "${logname}.json"
    collectInitLogsFromClient1 ${LOGBASEFOLDER}
    stopMiddleware1
}

collectInitLogsFromClient1() {
    #args
    # $1: path where the logfiles will be stored
    destPath=$1
    logname="client1_init"
    mv ${logname}.log ${destPath}/${logname}.log
    mv ${logname}.json ${destPath}/${logname}.json
}

stopMemcachedServers() {
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER1IP} "screen -X -S ${SERVER1DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER2IP} "screen -X -S ${SERVER2DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER3IP} "screen -X -S ${SERVER3DESIGNATOR} quit"
    removeFile ${SERVER1IP} "~/screenlog.0"
    removeFile ${SERVER2IP} "~/screenlog.0"
    removeFile ${SERVER3IP} "~/screenlog.0"
}

runMemtierClient() {
    #args: 
    # $1: ip to connect to
    # $2: port to connect to
    # $3: num_clients
    # $4: ratio e.g. ${READONLY}
    # $5: designator e.g. "client1"
    # $6: numThreads e.g. 2
    # $7: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    # $8: client_IP (if not locally executed)
    ip=$1
    port=$2
    numClients=$3
    ratio=$4
    designator=$5
    numThreads=$6
    instance=$7
    logname=${designator}${instance}
    baseCmd="memtier_benchmark --server=${ip} --port=${port} --clients=${numClients} --test-time=${TESTTIME} --ratio=${ratio} --protocol=memcache_text --run-count=1 --threads=${numThreads} --key-maximum=10000  --data-size=4096 --out-file=${logname}.log --json-out-file=${logname}.json"
    if [[ $# -eq 7 ]]; then
        if [[ instance == ${FIRSTMEMTIER} ]]; then
            log "starting memtier ${designator} (local, ${instance}) connected to ${ip}:${port} with clients=${numClients} threads=${numThreads} and a ratio of ${ratio} writing logs to ${logname}_screenlog.0"
            cmd="${baseCmd} &> ${logname}_screenlog.0"
            #run the command
            log "$cmd"
            $cmd
        else
            log "starting memtier ${designator} (local, ${instance}) connected to ${ip}:${port} with clients=${numClients} threads=${numThreads} and a ratio of ${ratio} writing logs to screenlog.0"
            screen -dm -L -S ${designator} ${baseCmd}
            #screen -dm -L -S ${designator} memtier_benchmark --server=${ip} --port=${port} --clients=${numClients} --test-time=${TESTTIME} --ratio=${ratio} --protocol=memcache_text --run-count=1 --threads=${numThreads} --key-maximum=10000  --data-size=4096 --out-file=${designator}${instance}.log --json-out-file=${designator}${instance}.json
        fi
    elif [[ $# -eq 8 ]]; then
        clientIP=$8
        log "starting memtier ${designator} (remote, ${instance}) connected to ${ip}:${port} with clients=${numClients} threads=${numThreads} and a ratio of ${ratio} writing logs to screenlog.0"
        ssh -o StrictHostKeyChecking=no junkerp@${clientIP} "screen -dm -L -S ${designator} ${baseCmd}"
        #ssh -o StrictHostKeyChecking=no junkerp@${clientIP} "screen -dm -L -S client memtier_benchmark --server=${ip} --port=${port} --clients=$3 --test-time=${TESTTIME} --ratio=${ratio} --protocol=memcache_text --run-count=1 --threads=${numThreads} --key-maximum=10000  --data-size=4096 --out-file=${designator}${instance}.log --json-out-file=${designator}${instance}.json"
    else
        log "ERROR: invalid number of arguments (expected 7 for local and 8 for remote client execution): $#"
    fi
}

startMiddleware() {
    #args:
    # $1: middleware_IP 
    # $2: designator e.g. "middleware1"
    # $3: numServers
    ip=$1
    designator=$2
    numServers=$3
    log "Starting $designator with $numServers servers (ip=$ip)"
    if [[ $3 -eq 1 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@$ip "cd asl; screen -L -dm -S $designator java -jar dist/middleware-junkerp.jar  -l $ip -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT}"
    elif [[ $3 -eq 2 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@$ip "cd asl; screen -L -dm -S $designator java -jar dist/middleware-junkerp.jar  -l $ip -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT}"
    elif [[ $3 -eq 3 ]]; then
        ssh -o StrictHostKeyChecking=no junkerp@$ip "cd asl; screen -L -dm -S $designator java -jar dist/middleware-junkerp.jar  -l $ip -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
    else
        log "ERROR: cannot start middleware. Invalid parameter for numServers: $numServers"
    fi
}

stopMiddleware() {
    #args:
    # $1: middleware_IP
    # $2: designator e.g. "middleware1"
    log "Stopping $2 (ip=$2)"
    ssh -o StrictHostKeyChecking=no junkerp@$1 "screen -X -S $2 quit"
}

stopMiddleware1() {
    stopMiddleware ${MW1IP} ${MW1DESIGNATOR}
}

stopMiddleware2() {
    stopMiddleware ${MW2IP} ${MW2DESIGNATOR}
}

startMiddleware1() {
    #args
    # $1: numServers
    startMiddleware ${MW1IP} ${MW1DESIGNATOR} $1
}

startMiddleware2() {
    #args
    # $1: numServers
    startMiddleware ${MW2IP} ${MW2DESIGNATOR} $1
}
