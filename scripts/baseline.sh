#!/bin/bash
#Run this script from one of the memcached servers
server1="10.0.0.8" # this is the current server
server2="10.0.0.7"
server3="10.0.0.11"
client1="10.0.0.5"
client2="10.0.0.6"
client3="10.0.0.4"
MW1="10.0.0.10"
MW2="10.0.0.9"
# Setup, start memcached servers, fill them with data
screen -L -dm -S server1 memcached -p 11212 -vv &> server1.log
ssh -o StrictHostKeyChecking=no junkerp@${server2} "screen -L -dm -S server2 memcached -p 11212 -vv &> server2.log"
ssh -o StrictHostKeyChecking=no junkerp@${server3} "screen -L -dm -S server3 memcached -p 11212 -vv &> server3.log"

# start middleware1
ssh -o StrictHostKeyChecking=no junkerp@${MW1} "screen -L -dm -S middleware1 cd asl; java -jar dist/middleware-junkerp.jar  -l ${MW1} -p 1234 -t 2 -s true -m ${server1}:11212 ${server2}:11212 ${server3}:11212 &> middleware1.log"
# initialize memcached servers with all keys
ssh -o StrictHostKeyChecking=no junkerp@${client1} 'memtier_benchmark --server=${MW1} --port=11212 --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --debug --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S &> memtier1.log'
#run the command
# TODO: check if this script only continues when cmd is done
#
# 2.1 a) Read only, 3 memtier clients with 2 threads each, 1 memcached server
# virtual clients per memtier client 1..32
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

# ssh -v -o StrictHostKeyChecking=no junkerp@10.0.0.5 'memtier_benchmark --server=10.0.0.10 --port=11212 --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --debug --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S &> memtier1.log'