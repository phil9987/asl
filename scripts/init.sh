#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
# initialize systems
logBaseFolder="${LOGBASEFOLDER}"
log "Creating folder for logfiles: ${logBaseFolder}"
createDirectory ${logBaseFolder}
createRemoteDirectory ${CLIENT2IP} ~/asl/logs
createRemoteDirectory ${CLIENT3IP} ~/asl/logs
createRemoteDirectory ${SERVER1IP} ~/asl/logs
createRemoteDirectory ${SERVER2IP} ~/asl/logs
createRemoteDirectory ${SERVER3IP} ~/asl/logs
createRemoteDirectory ${MW1IP} ~/asl/logs
createRemoteDirectory ${MW2IP} ~/asl/logs

startMemcachedServers
initMemcachedServers