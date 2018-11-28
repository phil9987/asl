
# coding: utf-8

# In[3]:


get_ipython().magic(u'matplotlib inline')
import matplotlib
#matplotlib.use('Agg') # So we can save the figures to .png files
import matplotlib.pyplot as plt
import os
import json


def plot_generic(xs, ys, yerrs=None, labels='', fmt=".-", markersize=8, capsize=8,
         ymax=None, title='', xlabel='', ylabel='',
         xticks=None, yticks=None, save_file=None, size=None):
    '''
    xs          [x1,..,xn] or [[x1,..,xn],[x1,..,xn],...,[x1,..,xn]]
                    x-axis values. If multiple lines are plotted, should use identical values.
    ys          [y1,..,yn] or [[y11,..,y1n],[y21,..,y2n],...,[ym1,..,ymn]]
                    y-axis values. Possible to plot multiple lines on one plot.
    yerrs       Stdev for ys, same dim as ys. If None, will be ignored
    labels      Label of graphs, sring or list of strings
    fmt         Matplotlib line styles. Single style or list of styles
    markersize  Size of datapoints
    capsize     Size of horizontal bars of errorbars
    ymax        Y-axis max. Single integer.
    xlabel      X-axis label
    ylabel      Y-axis label
    xticks      Can be None
    yticks      Can be None
    save_file   String w/ eps extension
    size        Size of figure. Affects resolution (?). Can be None.
    '''

    if not isinstance(xs[0], list):
        xs = [xs]
        ys = [ys]
        if yerrs is not None:
            yerrs = [yerrs]
        labels = [labels]
        fmt = [fmt]

    fig, ax = plt.subplots(figsize=size)
    
    # Plot with error bars
    if yerrs is not None:
        y_tmp = -1
        for (x, y, yerr, label, f) in zip(xs, ys, yerrs, labels, fmt):
            if yerr is not None:
                ax.errorbar(x, y, yerr=yerr, fmt=f, markersize=markersize, capsize=capsize, label=label)
            else:
                ax.plot(x, y, f, markersize=markersize, label=label)
            if ymax is None and y_tmp < max(y):
                y_tmp = max(y)
        if ymax is None:
            ymax = 1.1*y_tmp
        ax.set_ylim(bottom=0, top=ymax)
    else: # Plot without error bars
        y_tmp = -1
        for (x, y, label, f) in zip(xs, ys, labels, fmt):
            ax.plot(x, y, f, markersize=markersize, label=label)
            if ymax is None and y_tmp < max(y):
                y_tmp = max(y)
        if ymax is None:
            ymax = 1.1*y_tmp
        ax.set_ylim(ymin=0, ymax=ymax)
    
    legend = ax.legend(loc='best', shadow=False)
    plt.title(title)
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    if xticks is not None:
        plt.xticks(xticks)
    if yticks is not None:
        plt.yticks(yticks)
    plt.savefig(save_file, format='eps', dpi=1000)
    #plt.savefig(save_file)
    plt.show()
    plt.clf()


# In[4]:


jsonfile = './plotdata/logSection2_1a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['-1']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.1 read only memtier throughput', xlabel='# memtier clients', ylabel='average throughput (requests / second)', labels='throughput', save_file='test.eps')


# In[ ]:


jsonfile = './plotdata/logSection2_1b.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['-1']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
plt.axis([0, 43, 0, 20000])
plt.figure(2)
latencyJson = jsondata['memtierLatency']['-1']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
plt.axis([0, 43, 0.0, 0.015])
print(latency)
plt.show()


# In[ ]:


jsonfile = './plotdata/logSection2_2a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['-1']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
plt.axis([0, 6.5, 0, 7000])
plt.figure(2)
latencyJson = jsondata['memtierLatency']['-1']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
plt.axis([0, 6.5, 0.0, 0.004])
print(latency)
plt.show()


# In[ ]:


jsonfile = './plotdata/logSection3_1a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['8']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
plt.axis([0, 6.5, 0, 3500])
throughputJson = jsondata['memtierThroughput']['16']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='b.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['32']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['64']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
plt.figure(2)
latencyJson = jsondata['memtierLatency']['8']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
latencyJson = jsondata['memtierLatency']['16']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'b.-')
latencyJson = jsondata['memtierLatency']['32']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
latencyJson = jsondata['memtierLatency']['64']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
plt.axis([0, 6.5, 0.0, 0.015])
print(latency)
plt.show()


# In[ ]:


jsonfile = './plotdata/logSection3_1b.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['8']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['16']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['32']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='b.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['64']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='.-', capsize=3)
plt.axis([0, 43, 0, 20000])
plt.figure(2)
latencyJson = jsondata['memtierLatency']['8']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
latencyJson = jsondata['memtierLatency']['16']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
latencyJson = jsondata['memtierLatency']['32']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'b.-')
latencyJson = jsondata['memtierLatency']['64']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, '.-')
plt.axis([0, 43, 0.0, 0.025])
print(latency)
plt.show()


# In[ ]:


jsonfile = './plotdata/logSection3_2a.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['8']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
plt.axis([0, 6.5, 0, 3500])
throughputJson = jsondata['memtierThroughput']['16']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='b.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['32']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['64']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
plt.figure(2)
latencyJson = jsondata['memtierLatency']['8']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
latencyJson = jsondata['memtierLatency']['16']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'b.-')
latencyJson = jsondata['memtierLatency']['32']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
latencyJson = jsondata['memtierLatency']['64']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
plt.axis([0, 6.5, 0.0, 0.015])
print(latency)
plt.show()


# In[ ]:


jsonfile = './plotdata/logSection3_2b.plotdata'
jsondata = json.load(open(jsonfile, 'r'))
throughputJson = jsondata['memtierThroughput']['8']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.figure(1)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='r.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['16']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='g.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['32']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='b.-', capsize=3)
throughputJson = jsondata['memtierThroughput']['64']
throughputJson.sort(key=lambda tup: tup[0])
memtierCli, throughput, stddev = zip(*throughputJson)
print(memtierCli)
print(throughput)
print(stddev)
plt.errorbar(memtierCli, throughput, yerr=stddev, fmt='.-', capsize=3)
plt.axis([0, 43, 0, 20000])
plt.figure(2)
latencyJson = jsondata['memtierLatency']['8']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'r.-')
latencyJson = jsondata['memtierLatency']['16']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'g.-')
latencyJson = jsondata['memtierLatency']['32']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, 'b.-')
latencyJson = jsondata['memtierLatency']['64']
latencyJson.sort(key=lambda tup: tup[0])
memtierCli, latency, stddev = zip(*latencyJson)
plt.plot(memtierCli, latency, '.-')
plt.axis([0, 43, 0.0, 0.025])
print(latency)
plt.show()

