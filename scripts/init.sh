#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
# initialize systems
startMemcachedServers
initMemcachedServers
logBaseFolder="${LOGBASEFOLDER}"
log "Creating folder for logfiles: $logBaseFolder"
createDirectory $logBaseFolder