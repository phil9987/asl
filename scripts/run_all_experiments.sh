#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
./init.sh
./baseline.sh
#./baselineMiddleware.sh
./cleanup.sh