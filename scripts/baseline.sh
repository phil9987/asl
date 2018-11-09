#!/bin/bash
#Run this script from the first memtier client
#Make sure helper.sh is in the same directory
echo "$PWD"
. helperFunctions.sh
. variables.sh
# initialize systems
startMemcachedServers
initMemcachedServers
#
# 2.1 a) Read only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
: 'log "Starting experiment for section 2.1a)"
#define parameter ranges
memtierClients=(1 8 16 32)
numRepetitions=3
ratio=1:0

for i in {1..numRepetitions}
do
   log "Starting run $i of section 2.1a)"
   for c in "${memtierClients[@]}"; do
	for th in "${threads[@]}"; do
		#add parameters to the command
        cmd="memtier_benchmark --server=${MW1IP} --port=${MWPORT} --clients=${c} --test-time=${time} --ratio=${READ_ONLY} --protocol=memcache_text --run-count=1 --threads=2 --key-maximum=10000  --data-size=4096 &> client1.log"
		#run the command
		log $cmd
		$cmd
	done
done
done 
'
#
#
# 2.1 b) Write only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
#
# 2.2a) Read only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32
#
# 2.2b) Write only, 2 memtier clients with 1 thread each, 2 memcached server
# virtual clients per memtier client 1..32
# ssh -v -o StrictHostKeyChecking=no junkerp@10.0.0.10 "cd asl; screen -L -dm -S middleware1 java -jar dist/middleware-junkerp.jar  -l 10.0.0.10 -p 1234 -t 2 -s true -m 10.0.0.8:11212 10.0.0.7:11212 10.0.0.11:11212 &> logs/middleware1.log"
# memtier_benchmark --server=10.0.0.8 --port=11212 --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --debug --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S
# Cleanup


