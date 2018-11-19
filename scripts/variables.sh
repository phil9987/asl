#!/bin/bash
REPETITIONS=2
TESTTIME=5
SERVER1IP="10.0.0.8" # this is the current server
SERVER1DESIGNATOR="server1"
SERVER2IP="10.0.0.7"
SERVER2DESIGNATOR="server2"
SERVER3IP="10.0.0.11"
SERVER3DESIGNATOR="server3"
MEMCACHEDPORT="11212"
CLIENT1IP="10.0.0.5"
CLIENT1DESIGNATOR="client1"
CLIENT2IP="10.0.0.6"
CLIENT2DESIGNATOR="client2"
CLIENT3IP="10.0.0.4"
CLIENT3DESIGNATOR="client3"
MW1IP="10.0.0.10"
MW1DESIGNATOR="middleware1"
MW2IP="10.0.0.9"
MW2DESIGNATOR="middleware2"
MWPORT="1234"
READONLY="0:1"
WRITEONLY="1:0"
LOGBASEFOLDER="experiment_logs"
FIRSTMEMTIER="FIRST"
SECONDMEMTIER="SECOND"
DSTATDESIGNATOR="DSTAT"
DSTATFILE="./asl/logs/dstat.csv"
PINGDESIGNATOR="PING"
PINGFILE="./asl/logs/ping."
SHARDED="true"
NONSHARDED="false"