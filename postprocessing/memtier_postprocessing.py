import json
import os

def loadMemtierRes(jsonfilename):
    with open(jsonfilename) as f:
        jf = json.load(f)
        avgLatency = jf['ALL STATS']['Totals']['Latency']
        operationsPerSecond = jf['ALL STATS']['Totals']['Ops/sec']
        testTime = jf['configuration']['test_time']
        totalThroughput = testTime * operationsPerSecond
        print("throughput={} avgLatency={}".format(totalThroughput, avgLatency))
        return totalThroughput, avgLatency

def main():
    thruput1, avgLatency1 = loadMemtierRes('./client1FIRST.json')
    thruput2, avgLatency2 = loadMemtierRes('./client2FIRST.json')
    thruput3, avgLatency3 = loadMemtierRes('./client3FIRST.json')
    totalThroughput=thruput1 + thruput2 + thruput3
    avgLatency = (avgLatency1 + avgLatency2 + avgLatency3) / 3.0
    print("totalThroughput={} totalAvgLatency={}".format(totalThroughput, avgLatency))
    
    # todo: take as input a directory and take all the *.json files in this directory as input for the calculation

if __name__ == "__main__":
    main()