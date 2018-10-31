#!/bin/bash
# Run this script from one of the memcached servers
# server1 = "10.0.0.4" # this is the current server
server2="10.0.0.10"
server3="10.0.0.9"
client1="10.0.0.7"
client2="10.0.0.5"
client3="10.0.0.6"
MW1="10.0.0.11"
MW2="10.0.0.8"
# Setup, start memcached servers, fill them with data
screen -dm -S server1 "memcached -p 11212 -vv"
screen -dm -S server2 "ssh -o StrictHostKeyChecking=no junkerp@${server2} 'memcached -p 11212 -vv'"
screen -dm -S server3 "ssh -o StrictHostKeyChecking=no junkerp@${server3} 'memcached -p 11212 -vv'"
# start middleware1
screen -dm -S middleware1 "ssh -o StrictHostKeyChecking=no junkerp@${MW1} 'cd asl; java -jar dist/middleware-junkerp.jar  -l ${MW1} -p 1234 -t 2 -s true -m ${server1}:11212 ${server2}:11212 ${server3}:11212'"
# initialize memcached servers with all keys
cmd="ssh -o StrictHostKeyChecking=no junkerp@${client1} 'memtier_benchmark --server=${MW1} --port=11212 --clients=1 --requests=10000 --protocol=memcache_text --run-count=1 --threads=1 --debug --key-maximum=10000 --ratio=1:0 --data-size=4096 --key-pattern=S:S'"
#run the command
echo $cmd
$cmd
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