#!/bin/bash
#Make sure variables.sh is in the same directory
source variables.sh

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
    startDstat ${CLIENT1IP} ${CLIENT1DESIGNATOR}
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

stopDstatAndCopyFile() {
    #args
    # $1: ip
    # $2: designator
    # $3: path to store file
    ip=$1
    designator=$2
    path=$3
    designatordstat="${designator}${DSTATDESIGNATOR}"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -X -S ${designatordstat} quit"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/${DSTATFILE} ${path}/${designator}_${DSTATFILE}
    removeFile ${ip} ${DSTATFILE}
}

stopDstatAndCopyFileMW1() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${MW1IP} ${MW1DESIGNATOR} ${path}
}

stopDstatAndCopyFileMW2() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${MW2IP} ${MW2DESIGNATOR} ${path}
}

stopDstatAndCopyFileClient1() {
    # this is the local machine
    #args
    # $1: path to store file
    path=$1
    designatordstat="${CLIENT1DESIGNATOR}${DSTATDESIGNATOR}"
    screen -X -S ${designatordstat} quit
    mv ~/${DSTATFILE} ${path}/${CLIENT1DESIGNATOR}_${DSTATFILE}
}

stopDstatAndCopyFileClient2() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${CLIENT2IP} ${CLIENT2DESIGNATOR} ${path}
}

stopDstatAndCopyFileClient3() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${CLIENT3IP} ${CLIENT3DESIGNATOR} ${path}
}

stopDstatAndCopyFileServer1() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${SERVER1IP} ${SERVER1DESIGNATOR} ${path}
}

stopDstatAndCopyFileServer2() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${SERVER2IP} ${SERVER2DESIGNATOR} ${path}
}

stopDstatAndCopyFileServer3() {
    #args
    # $1: path to store file
    path=$1
    stopDstatAndCopyFile ${SERVER3IP} ${SERVER3DESIGNATOR} ${path}
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
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -dm -S ${designatorping} bash -c 'ping -nD ${iptoping} &> ${designator}${PINGFILE}'"
}

stopPingAndCopyFile() {
    #args
    # $1: ip
    # $2: designator origin
    # $3: path to store file
    # $4: designator destination
    ip=$1
    designator="${2}${4}"
    path=$3
    designatorping="${designator}${PINGDESIGNATOR}"
    echo "stopping ping on $ip with desitnatorping=$designatorping path=$path"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "screen -X -S ${designatorping} quit"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/${designator}${PINGFILE} ${path}/${designator}${PINGFILE}
    removeFile ${ip} ${designator}${PINGFILE}
}

stopPingAndCopyFileMW1() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${MW1IP} ${MW1DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileMW2() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${MW2IP} ${MW2DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileClient1() {
    # this is the local machine running the script
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    designator=${CLIENT1DESIGNATOR}${designator2}
    designatorping="${designator}${PINGDESIGNATOR}"
    screen -X -S ${designatorping} quit
    mv ~/${designator}${PINGFILE} ${path}/${designator}${PINGFILE}
}

stopPingAndCopyFileClient2() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${CLIENT2IP} ${CLIENT2DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileClient3() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${CLIENT3IP} ${CLIENT3DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileServer1() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${SERVER1IP} ${SERVER1DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileServer2() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${SERVER2IP} ${SERVER2DESIGNATOR} ${path} ${designator2}
}

stopPingAndCopyFileServer3() {
    #args
    # $1: path to store file
    # $2: designator destination
    path=$1
    designator2=$2
    stopPingAndCopyFile ${SERVER3IP} ${SERVER3DESIGNATOR} ${path} ${designator2}
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

# collect all relevant logs from a middleware vm and removes the screenlog.0 logfile from screen
collectLogsFromMiddleware() {
    #args
    # $1: path to copy the logfiles to
    # $2: middlewareip
    # $3: designator
    path=$1
    ip=$2
    designator=$3
    echo "Collecting logs from ${designator} ($ip, $path)"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/requests.log ${path}/${designator}_requests.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/error.log ${path}/${designator}_error.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/asl/logs/debug.log ${path}/${designator}_debug.log
}

# collects all relevant logs from MW1
collectLogsFromMiddleware1() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogsFromMiddleware ${path} ${MW1IP} ${MW1DESIGNATOR}
}

# collects all relevant logs from MW2
collectLogsFromMiddleware2() {
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogsFromMiddleware ${path} ${MW2IP} ${MW2DESIGNATOR}
}

# collects all relevant logs from a memcached server vm and removes the screenlog.0 logfile from screen
collectLogsFromServer() {
    #args
    # $1: path to copy the logfiles to
    # $2: serverip
    # $3: designator
    path=$1
    ip=$2
    designator=$3
    echo "Collecting logs from server ${designator} (${ip}, ${path})"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/screenlog.0 ${path}/${designator}_screenlog0.log
}

# collects all relevant logs from SERVER1
collectLogsFromServer1(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogsFromServer ${path} ${SERVER1IP} ${SERVER1DESIGNATOR}
}

# collects all relevant logs from SERVER2
collectLogsFromServer2(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogsFromServer ${path} ${SERVER2IP} ${SERVER2DESIGNATOR}
}

# collects all relevant logs from SERVER3
collectLogsFromServer3(){
    #args
    # $1: path to copy the logfiles to
    path=$1
    collectLogsFromServer ${path} ${SERVER3IP} ${SERVER3DESIGNATOR}
}

# collects all relevant logs from a memtier client vm and removes the screenlog.0 logfile from screen
collectLogsFromClient() {
    #args
    # $1: path to copy the logfiles to
    # $2: clientip
    # $3: designator
    path=$1
    ip=$2
    designator=$3
    echo "Collecting logs from ${designator} (${ip}, ${path})"
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/${designator}.log ${path}/${designator}.log
    scp -o StrictHostKeyChecking=no junkerp@${ip}:~/${designator}.json ${path}/${designator}.json
}

# collects the logfiles from client1 (client from which script is executed)
collectLogsFromClient1() {
    # This client is the one running the commands, hence it is local
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    path=$1
    instance=$2
    logname=${CLIENT1DESIGNATOR}${instance}
    echo "Collecting logs from ${logname} (local, ${path})"
    mv ${logname}.log ${path}/${logname}.log
    mv ${logname}.json ${path}/${logname}.json
}

# collects all relevant logs from CLIENT2
collectLogsFromClient2() {
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    path=$1
    instance=$2
    logname=${CLIENT2DESIGNATOR}${instance}
    collectLogsFromClient ${path} ${CLIENT2IP} ${logname}
}

# collects all relevant logs from CLIENT2
collectLogsFromClient3() {
    #args
    # $1: path to copy the logfiles to
    # $2: ${FIRSTMEMTIER} if this is the first instance of memtier on this machine or ${SECONDMEMTIER} if this is the second instance
    path=$1
    instance=$2
    logname=${CLIENT3DESIGNATOR}${instance}
    collectLogsFromClient ${path} ${CLIENT3IP} ${logname}
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
    stopMiddleware1
    collectInitLogsFromClient1 ${LOGBASEFOLDER}
    collectLogsFromMiddleware1 ${LOGBASEFOLDER}
}

# collects the memtier logs which were created during the init of the memcached servers
collectInitLogsFromClient1() {
    #args
    # $1: path where the logfiles will be stored
    destPath=$1
    logname="client1_init"
    mv ${logname}.log ${destPath}/${logname}.log
    mv ${logname}.json ${destPath}/${logname}.json
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
    sleep 2
}

waitForFileToExist() {
    #args:
    # $1: ip
    # $2: path/to/file.info
    ip=$1
    file=$2
    while [[ ! -f ${file} ]]; do
        :
    done
}

# stops a middleware
stopMiddleware() {
    #args:
    # $1: middleware_IP
    # $2: designator e.g. "middleware1"
    ip=$1
    designator=$2
    log "Stopping ${designator} (ip=${ip})"
    screencmd="screen -X -S ${designator} quit; ls; while [[ ! -f ~/asl/logs/done.info ]]; do sleep 0.1; done; rm ~/asl/logs/done.info;"
    # TODO test this command with timeout and escaped cnt variable
    #screencmd="screen -X -S ${designator} quit; ls; bash -c 'cnt=0; while [[ ! -f ~/asl/logs/done.info && \${cnt} -lt 50 ]]; do cnt=$((cnt + 1)); sleep 0.1; done; rm ~/asl/logs/done.info;'"
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "${screencmd}"
}

# stops MW1
stopMiddleware1() {
    stopMiddleware ${MW1IP} ${MW1DESIGNATOR}
}

# stops MW2
stopMiddleware2() {
    stopMiddleware ${MW2IP} ${MW2DESIGNATOR}
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