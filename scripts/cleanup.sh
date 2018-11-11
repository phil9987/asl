#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
source helperFunctions.sh
source variables.sh
logBaseFolder="${LOGBASEFOLDER}"
moveExperimentLog ${logBaseFolder}
newLogBaseFolder="${LOGBASEFOLDER}_$(date '+%d-%m-%Y_%H-%M-%S')"
mv ./${logBaseFolder} ./${newLogBaseFolder}
stopMemcachedServers