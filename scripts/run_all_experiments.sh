#!/bin/bash
#Run this script from the first memtier client
#Make sure variables.sh and helperFunctions.sh are in the same directory
echo "running run all experiments script..."
./init.sh
#./repeat5.sh
#./sec2_baseline.sh
./sec2_baselineExtended.sh
#./sec3_baselineMW.sh
./sec3_baselineMWExtended.sh
./sec4_writeExtended.sh
#./sec4_write.sh
#./sec5_multigets.sh
#./sec6_2k.sh
./cleanup.sh
echo "done running run all experiments script"