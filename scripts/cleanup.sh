#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
# initialize systems
startMemcachedServers
initMemcachedServers
#logBaseFolder="experiments_$(date '+%d-%m-%Y_%H-%M-%S')"
logBaseFolder="${LOGBASEFOLDER}"
newLogBaseFolder="${LOGBASEFOLDER}_$(date '+%d-%m-%Y_%H-%M-%S')"
log "Renaming folder for logfiles: $newLogBaseFolder"
mv ./$logBaseFolder ./$newLogBaseFolder
log "Shutting down memcached servers"
stopMemcachedServers