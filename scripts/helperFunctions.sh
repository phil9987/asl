#!/bin/bash

source variables.sh
# logs argument string to file
log () {
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "$dt $1" >> experiment.log
}

# Starts all 3 servers
startMemcachedServers() {    
    # Setup, start memcached servers, fill them with data
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER1IP} "screen -L -dm -S server1 memcached -p ${MEMCACHEDPORT} -vv"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER2IP} "screen -L -dm -S server2 memcached -p ${MEMCACHEDPORT} -vv"
    ssh -o StrictHostKeyChecking=no junkerp@${SERVER3IP} "screen -L -dm -S server3 memcached -p ${MEMCACHEDPORT} -vv"
    log "initializing servers.. sleeping for 2s"
    sleep 2s
}

initMemcachedServers() {
    # start middleware1
    ssh -o StrictHostKeyChecking=no junkerp@${MW1IP} "cd asl; screen -L -dm -S middleware1 java -jar dist/middleware-junkerp.jar  -l ${MW1} -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
    log "initializing middleware.. sleeping for 2s"
    sleep 2s
    # initialize memcached servers with all keys
    memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --debug --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S &> client1.log
    log "servers with values initialized"
}

startMemtier() {
    #args: 
    # $1: middleware_IP
    # $2: num_clients
    # $3: test_time in seconds
    # $4: ratio e.g. ${READONLY}
    # $5: logfilename the filename where the memtier output will be stored
    cmd="memtier_benchmark --server=$1 --port=${MWPORT} --clients=$2 --test-time=$3 --ratio=$4 --protocol=memcache_text --run-count=1 --threads=2 --key-maximum=10000  --data-size=4096 &> $5"
    #run the command
    log $cmd
    $cmd
}

startMiddleware() {
    #args:
    # $1: middleware_IP 
    # $2: designator e.g. "middleware1"
    # $3: numServers
    if [[ $3 == 1 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT}"
    elif [[ $3 == 2 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT}"
    elif [[ $3 == 3 ]]; then
        log "Starting middleware with ip $1 using designator $2 and $3 servers"
        ssh -o StrictHostKeyChecking=no junkerp@$1 "cd asl; screen -L -dm -S $2 java -jar dist/middleware-junkerp.jar  -l $1 -p ${MWPORT} -t 2 -s true -m ${SERVER1IP}:${MEMCACHEDPORT} ${SERVER2IP}:${MEMCACHEDPORT} ${SERVER3IP}:${MEMCACHEDPORT}"
    else
        log "ERROR: cannot start middleware. Invalid parameter for numServers: $3"
    fi
}

