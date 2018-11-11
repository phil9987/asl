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
moveExperimentLog ${logBaseFolder}
newLogBaseFolder="${LOGBASEFOLDER}_$(date '+%d-%m-%Y_%H-%M-%S')"
mv ./${logBaseFolder} ./${newLogBaseFolder}
stopMemcachedServers