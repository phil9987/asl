#!/bin/bash
#Make sure variables.sh is in the same directory
source variables.sh

killScreen() {
    #args
    # $1: ip
    ssh -o StrictHostKeyChecking=no junkerp@${ip} "killall screen"
}
killall screen  # kill it also on client1 who runs the script
killScreen ${CLIENT2IP}
killScreen ${CLIENT3IP}
killScreen ${MW1IP}
killScreen ${MW2IP}
killScreen ${SERVER1IP}
killScreen ${SERVER2IP}
killScreen ${SERVER3IP}
