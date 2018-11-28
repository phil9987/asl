#!/bin/bash
source variables.sh
source helperFunctions.sh

startIperfServer ${MW1IP}
sleep 2s
echo "client1 <-> MW1"
startIperfClientBlocking ${CLIENT1IP} ${MW1IP}
echo "client2 <-> MW1"
startIperfClientBlocking ${CLIENT2IP} ${MW1IP}
echo "client3 <-> MW1"
startIperfClientBlocking ${CLIENT3IP} ${MW1IP}
echo "server1 <-> MW1"
startIperfClientBlocking ${SERVER1IP} ${MW1IP}
echo "server2 <-> MW1"
startIperfClientBlocking ${SERVER2IP} ${MW1IP}
echo "server3 <-> MW1"
startIperfClientBlocking ${SERVER3IP} ${MW1IP}
killScreen ${MW1IP}

startIperfServer ${MW2IP}
sleep 2s
echo "client1 <-> MW2"
startIperfClientBlocking ${CLIENT1IP} ${MW2IP}
echo "client2 <-> MW2"
startIperfClientBlocking ${CLIENT2IP} ${MW2IP}
echo "client3 <-> MW2"
startIperfClientBlocking ${CLIENT3IP} ${MW2IP}
echo "server1 <-> MW2"
startIperfClientBlocking ${SERVER1IP} ${MW2IP}
echo "server2 <-> MW2"
startIperfClientBlocking ${SERVER2IP} ${MW2IP}
echo "server3 <-> MW2"
startIperfClientBlocking ${SERVER3IP} ${MW2IP}
killScreen ${MW2IP}

