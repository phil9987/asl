#!/bin/bash

. $PWD/variables.sh
# logs argument string to file
log () {
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "$dt $1" >> experiment.log
}

collectLogsFromMiddleware() {
    #args
    # $1: path to copy the logfiles to
    # $2: middlewareip
    # $3: designator
    scp -o StrictHostKeyChecking=no junkerp@$2:~/asl/screenlog.0 $1/$3_screenlog0.log
    scp -o StrictHostKeyChecking=no junkerp@$2:~/asl/logs/requests.log $1/$3_requests.log
    scp -o StrictHostKeyChecking=no junkerp@$2:~/asl/logs/error.log $1/$3_error.log
}

collectLogsFromServers() {
    #args
    # $1: path to copy the logfiles to
    scp -o StrictHostKeyChecking=no junkerp@${SERVER1IP}:~/screenlog.0 $1/${SERVER1DESIGNATOR}_screenlog0.log
    scp -o StrictHostKeyChecking=no junkerp@${SERVER2IP}:~/screenlog.0 $1/${SERVER2DESIGNATOR}_screenlog0.log
    scp -o StrictHostKeyChecking=no junkerp@${SERVER3IP}:~/screenlog.0 $1/${SERVER3DESIGNATOR}_screenlog0.log

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
    # start middleware1
    log "Function initMemcachedServers() entered"
    startMiddleware1 3
    log "Started middleware.. sleeping for 2s"
    sleep 2s
    # initialize memcached servers with all keys
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S --out-file=client1_init.log --json-out-file=client1_init.json
    log "servers with values initialized"
    stopMiddleware1
}

stopMemcachedServers() {
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER1IP} "screen -X -S ${SERVER1DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER2IP} "screen -X -S ${SERVER2DESIGNATOR} quit"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER3IP} "screen -X -S ${SERVER3DESIGNATOR} quit"
}

runMemtierClient() {
    #args: 
    # $1: middleware_IP
    # $2: num_clients
    # $3: ratio e.g. ${READONLY}
    # $4: designator e.g. "client1"
    # $5: client_IP (if not locally executed)
    if [[ $# -eq 4 ]]; then
        log "starting local memtier client connected to $1 with clients=$2 for $3s and a ratio of $4 writing logs to $5.log"
        cmd="memtier_benchmark --server=$1 --port=${MWPORT} --clients=$2 --test-time=${TESTTIME} --ratio=$3 --protocol=memcache_text --run-count=1 --threads=2 --key-maximum=10000  --data-size=4096 --out-file=$4.log --json-out-file=$4.json"
        #run the command
        log "$cmd"
        $cmd
    elif [[ $# -eq 5 ]]; then
        log "starting remote memtier client with ip $6 connected to $1 with clients=$2 for $3s and a ratio of $4 writing logs to $5"
        ssh -o StrictHostKeyChecking=no junkerp@$6 "screen -dm -S client memtier_benchmark --server=$1 --port=${MWPORT} --clients=$2 --test-time=${TESTTIME} --ratio=$3 --protocol=memcache_text --run-count=1 --threads=2 --key-maximum=10000  --data-size=4096 --out-file=$4.log --json-out-file=$4.json"
    else
        log "ERROR: invalid number of arguments (expected 5 for local and 6 for remote client execution): $#"
    fi
}

startMiddleware() {
    #args:
    # $1: middleware_IP 
    # $2: designator e.g. "middleware1"
    # $3: numServers
    if [[ $3 -eq 1 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT}"
    elif [[ $3 -eq 2 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT}"
    elif [[ $3 -eq 3 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
    else
        log "ERROR: cannot start middleware. Invalid parameter for numServers: $3"
    fi
}

stopMiddleware() {
    #args:
    # $1: middleware_IP
    # $2: designator e.g. "middleware1"
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
