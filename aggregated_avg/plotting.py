import matplotlib.pyplot as plt
import os
import json

jsonfile = './logSection2_1a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughput = jsondata['throughputMean']
latency = jsondata['latencyMean']
memtierCli = jsondata['memtierCli']
plt.figure(1)
print(throughput)
plt.plot(memtierCli, throughput, 'ro')
plt.axis([1, 6, 0, 200000])
plt.figure(2)
plt.plot(memtierCli, latency, 'ro')
plt.axis([1, 6, 0.0, 0.015])
plt.show()