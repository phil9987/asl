import matplotlib.pyplot as plt
import os
import json

jsonfile = './logSection2_1a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['-1']
memtierCli, throughput, stddev = zip(*throughputJson)
plt.figure(1)
plt.errorbar(memtierCli, throughput, xerr=stddev, fmt='r.')
plt.axis([1, 6, 0, 200000])
plt.figure(2)
latencyJson = jsondata['memtierLatency']['-1']
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'ro')
plt.axis([1, 6, 0.0, 0.015])
plt.show()