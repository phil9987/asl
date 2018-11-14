#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
./init.sh
./sec2_baseline.sh
./sec3_baselineMW.sh
./cleanup.sh