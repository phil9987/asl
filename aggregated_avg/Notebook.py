
# coding: utf-8

# In[1]:


get_ipython().magic(u'matplotlib inline')
import matplotlib
#matplotlib.use('Agg') # So we can save the figures to .png files
import matplotlib.pyplot as plt
import os
import json
import zipfile

def zipdir(path, ziph):
    # ziph is zipfile handle
    for root, dirs, files in os.walk(path):
        for file in files:
            ziph.write(os.path.join(root, file))


def plot_generic(xs, ys, yerrs=None, labels='', fmt=".-", markersize=6, linewidth=1, capsize=8,
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
        #fmt = [fmt]

    fig, ax = plt.subplots(figsize=size)
    
    # Plot with error bars
    if yerrs is not None:
        y_tmp = -1
        for (x, y, yerr, label) in zip(xs, ys, yerrs, labels):
            print(yerr)
            if yerr is not None:
                ax.errorbar(x, y, yerr=yerr, fmt=fmt, markersize=markersize, capsize=capsize, label=label, linewidth=linewidth)
            else:
                ax.plot(x, y, fmt, markersize=markersize, label=label, linewidth=linewidth)
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
    plt.grid(linestyle=':', linewidth=0.8)
    if xticks is not None:
        plt.xticks(xticks)
    if yticks is not None:
        plt.yticks(yticks)
    plt.savefig("./plots/{}".format(save_file), format='eps', dpi=1000)
    #plt.savefig(save_file)
    plt.show()
    plt.clf()
    
def getDataFromJsonNoWorkers(section, key, workers='-1'):
    jsonfile = './plotdata/logSection{}.plotdata'.format(section)
    jsondata = json.load(open(jsonfile, 'r'))
    throughputJson = jsondata[key][workers]
    throughputJson.sort(key=lambda tup: tup[0])
    x,y,s = zip(*throughputJson)
    return list(x), list(y), list(s)

def getDataFromJsonAllWorkers(section, key):
    xs = []
    ys = []
    stddevs = []
    labels = []
    for w in ['8','16','32','64']:
        x, y, stddev = getDataFromJsonNoWorkers(section, key, w)
        xs.append(x)
        ys.append(y)
        stddevs.append(stddev)
        labels.append("{} WT".format(w))
    return xs, ys, stddevs, labels

    


# In[2]:


memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_1a', 'memtierThroughput')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.1 Cumulative Client Throughput read only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels='throughput', save_file='2_1a_throughputMemtier.eps')
memtierCli, latency, stddev = getDataFromJsonNoWorkers('2_1a', 'memtierLatency')
print(memtierCli)
print(latency)
print(stddev)
plot_generic(memtierCli, latency, stddev, title='Section 2.1 Average Client Response Time read only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels='throughput', save_file='2_1a_latencyMemtier.eps')


# In[3]:


memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_1b', 'memtierThroughput')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.1 Cumulative Client Throughput write only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels='throughput', save_file='2_1b_throughputMemtier.eps')
memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_1b', 'memtierLatency')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.1 Average Client Response Time write only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels='throughput', save_file='2_1b_latencyMemtier.eps')


# In[4]:


memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_2a', 'memtierThroughput')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.2 Cumulative Client Throughput read only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels='throughput', save_file='2_2a_throughputMemtier.eps')
memtierCli, latency, stddev = getDataFromJsonNoWorkers('2_2a', 'memtierLatency')
print(memtierCli)
print(latency)
print(stddev)
plot_generic(memtierCli, latency, stddev, title='Section 2.2 Average Client Response Time read only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels='throughput', save_file='2_2a_latencyMemtier.eps')


# In[5]:


memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_2b', 'memtierThroughput')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.2 Cumulative Client Throughput write only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels='throughput', save_file='2_2b_throughputMemtier.eps')
memtierCli, throughput, stddev = getDataFromJsonNoWorkers('2_2b', 'memtierLatency')
print(memtierCli)
print(throughput)
print(stddev)
plot_generic(memtierCli, throughput, stddev, title='Section 2.2 Average Client Response Time write only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels='throughput', save_file='2_2b_latencyMemtier.eps')


# In[6]:


xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1a', 'memtierThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.1 Cumulative Client Throughput read only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_1a_throughputMemtier.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1a', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.1 Average Client Response Time read only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_1a_latencyMemtier.eps')

# middleware
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1a', 'mwThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.1 Cumulative Client Throughput read only (middleware)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_1a_throughputMiddleware.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1a', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.1 Average Client Response Time read only (middleware)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_1a_latencyMiddleware.eps')


# In[7]:


xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1b', 'memtierThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.1 Cumulative Client Throughput write only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_1b_throughputMemtier.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1b', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.1 Average Client Response Time write only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_1b_latencyMemtier.eps')

# middleware
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1b', 'mwThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.1 Cumulative Client Throughput write only (middleware)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_1b_throughputMiddleware.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1b', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.1 Average Client Response Time write only (middleware)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_1b_latencyMiddleware.eps')


# In[8]:


xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2a', 'memtierThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.2 Cumulative Client Throughput read only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_2a_throughputMemtier.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2a', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.2 Average Client Response Time read only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_2a_latencyMemtier.eps')

# middleware
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2a', 'mwThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.2 Cumulative Client Throughput read only (middleware)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_2a_throughputMiddleware.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2a', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.2 Average Client Response Time read only (middleware)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_2a_latencyMiddleware.eps')


# In[9]:


xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2b', 'memtierThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.2 Cumulative Client Throughput write only (memtier)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_2b_throughputMemtier.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2b', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.2 Average Client Response Time write only (memtier)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_2b_latencyMemtier.eps')

# middleware
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2b', 'mwThroughput')
plot_generic(xs, ys, stddevs, title='Section 3.2 Cumulative Client Throughput write only (middleware)', xlabel='Number of Clients', ylabel='Throughput [requests / second]', labels=labels, save_file='3_2b_throughputMiddleware.eps')
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2b', 'memtierLatency')
plot_generic(xs, ys, stddevs, title='Section 3.2 Average Client Response Time write only (middleware)', xlabel='Number of Clients', ylabel='Response Time [ms]', labels=labels, save_file='3_2b_latencyMiddleware.eps')


# In[10]:



zipf = zipfile.ZipFile('plots.zip', 'w', zipfile.ZIP_DEFLATED)
zipdir('./plots', zipf)
zipf.close()
print('done')

