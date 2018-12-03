#!/bin/bash
source variables.sh

startIperfServer() {
    #args
    # $1: ip
    ssh -o StrictHostKeyChecking=no junkerp@$1 "screen -dm -S iperf iperf -s"
}

startIperfClientBlocking() {
    #args
    # $1: ip of iperf client
    # $2: ip of iperf server to connect to
    ssh -o StrictHostKeyChecking=no junkerp@$1 "iperf -c $2 -r"
}

killScreen() {
    #args
    # $1: ip
    ssh -o StrictHostKeyChecking=no junkerp@$1 "killall screen"
}

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

startIperfServer ${SERVER1IP}
echo "client1 <-> SERVER1"
startIperfClientBlocking ${CLIENT1IP} ${SERVER1IP}
echo "client2 <-> SERVER1"
startIperfClientBlocking ${CLIENT2IP} ${SERVER1IP}
echo "client3 <-> SERVER1"
startIperfClientBlocking ${CLIENT3IP} ${SERVER1IP}
killScreen ${SERVER1IP}

startIperfServer ${SERVER2IP}
echo "client1 <-> SERVER2"
startIperfClientBlocking ${CLIENT1IP} ${SERVER2IP}
echo "client2 <-> SERVER2"
startIperfClientBlocking ${CLIENT2IP} ${SERVER2IP}
echo "client3 <-> SERVER2"
startIperfClientBlocking ${CLIENT3IP} ${SERVER2IP}
killScreen ${SERVER2IP}

startIperfServer ${SERVER3IP}
echo "client1 <-> SERVER3"
startIperfClientBlocking ${CLIENT1IP} ${SERVER3IP}
echo "client2 <-> SERVER3"
startIperfClientBlocking ${CLIENT2IP} ${SERVER3IP}
echo "client3 <-> SERVER3"
startIperfClientBlocking ${CLIENT3IP} ${SERVER3IP}
killScreen ${SERVER3IP}



