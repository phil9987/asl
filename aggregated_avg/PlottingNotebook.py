
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

def getDataFromJsonAllSpecialKeys(section, key, specialKeys, label):
    xs = []
    ys = []
    stddevs = []
    labels = []
    for w in specialKeys:
        x, y, stddev = getDataFromJsonNoWorkers(section, key, w)
        xs.append(x)
        ys.append(y)
        stddevs.append(stddev)
        labels.append("{} {}".format(w, label))
    return xs, ys, stddevs, labels

def getDataFromJsonAllWorkers(section, key):
    return getDataFromJsonAllSpecialKeys(section, key, ['8','16','32','64','128'], 'WT')

def getDataFromJsonSpecificWorkers(secion, key, workers):
    return getDataFromJsonAllSpecialKeys(secion, key, workers, 'WT')

def getDataFromJsonAllKeys(section, key):
    x = []
    y = []
    stddev = []
    for k in ['1','3','6','9']:
        x_, y_, stddev_ = getDataFromJsonNoWorkers(section, key, k)
        x.append(k)
        y.append(y_[0])
        stddev.append(stddev_[0])
    return x, y, stddev

def getDataFromJsonAdditionalMWPlot(section, workers):
    xs = []
    ys = []
    errs = []
    labels = ['Avg. Response Time', 'Avg. Queue Time', 'Avg. Service Time']
    relevantIdx = 0
    if workers is '8':
        relevantIdx = 2
    if workers is '16':
        relevantIdx = 3
    if workers is '32':
        relevantIdx = 4
    if workers is '64':
        relevantIdx = 5
    sec4data = []
    x,y,err = getDataFromJsonNoWorkers(section, 'mwLatency', workers)
    y = [nsToMs(el) for el in y]
    err = [nsToMs(el) for el in err]
    sec4data.append(y[relevantIdx])
    xs.append(x)
    ys.append(y)
    errs.append(err)
    x,y,err = getDataFromJsonNoWorkers(section, 'queuetime', workers)
    sec4data.append(y[relevantIdx])
    xs.append(x)
    ys.append(y)
    errs.append(err)
    x,y,err = getDataFromJsonNoWorkers(section, 'servicetime', workers)
    sec4data.append(y[relevantIdx])
    xs.append(x)
    ys.append(y)
    errs.append(err)
    x,y,err = getDataFromJsonNoWorkers(section, 'queuelen', workers)
    
    print("W{} responseT={} | queuetime={} | serviceTime={} | queuelen={}".format(workers, sec4data[0], sec4data[1], sec4data[2], y[relevantIdx]))
    return xs, ys, errs, labels
    

def numClients(numMemtier, numThreads, numClientsPerThread):
    return numMemtier*numThreads*numClientsPerThread

def calcXticks(xs1, xs2):
    x_ticks = set(xs1 + xs2)
    x_ticks = list(x_ticks)
    x_ticks.sort()
    return x_ticks
    
def nsToMs(t):
    return t/1000000

    


# In[3]:


x_ro, ys_ro, err_ro = getDataFromJsonNoWorkers('2_1a', 'memtierThroughput')
x_wo, ys_wo, err_wo = getDataFromJsonNoWorkers('2_1b', 'memtierThroughput')
x_ro = [numClients(3, 2, el) for el in x_ro]
x_wo = [numClients(3, 2, el) for el in x_wo]

print(calcXticks(x_ro, x_wo))
print(ys_ro)
print(ys_wo)

xs = [x_ro, x_wo]
ys = [ys_ro, ys_wo]
err = [err_ro, err_wo]
plot_generic(xs, ys, err, 
             title='Cumulative Client Throughput', 
             xlabel='Number of Clients', 
             ylabel='Throughput [requests / second]', 
             labels=['Read only', 'Write only'],
             xticks=[6, 18, 36, 72, 120, 192], 
             save_file='2_1_throughput.eps')

x_ro, ys_ro, err_ro = getDataFromJsonNoWorkers('2_1a', 'memtierLatency')
x_wo, ys_wo, err_wo = getDataFromJsonNoWorkers('2_1b', 'memtierLatency')
ys_ro = [el*1000 for el in ys_ro]
ys_wo = [el*1000 for el in ys_wo]
x_ro = [numClients(3, 2, el) for el in x_ro]
x_wo = [numClients(3, 2, el) for el in x_wo]
xs = [x_ro, x_wo]
ys = [ys_ro, ys_wo]
err = [err_ro, err_wo]
plot_generic(xs, ys, err, 
             title='Average Client Response Time', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=['Read only', 'Write only'],
             xticks=[6, 18, 36, 72, 120, 192], 
             save_file='2_1_latency.eps')


# In[4]:


x_ro, ys_ro, err_ro = getDataFromJsonNoWorkers('2_2a', 'memtierThroughput')
x_wo, ys_wo, err_wo = getDataFromJsonNoWorkers('2_2b', 'memtierThroughput')
x_ro = [numClients(1, 2, el) for el in x_ro]
x_wo = [numClients(1, 2, el) for el in x_wo]

print(calcXticks(x_ro, x_wo))
print(ys_ro)
print(ys_wo)

xs = [x_ro, x_wo]
ys = [ys_ro, ys_wo]
err = [err_ro, err_wo]
plot_generic(xs, ys, err, 
             title='Cumulative Client Throughput', 
             xlabel='Number of Clients', 
             ylabel='Throughput [requests / second]', 
             labels=['Read only', 'Write only'],
             xticks=[2, 4,6, 8, 12, 24, 64], 
             save_file='2_2_throughput.eps')


x_ro, ys_ro, err_ro = getDataFromJsonNoWorkers('2_2a', 'memtierLatency')
x_wo, ys_wo, err_wo = getDataFromJsonNoWorkers('2_2b', 'memtierLatency')
ys_ro = [el*1000 for el in ys_ro]
err_ro = [el*1000 for el in err_ro]
ys_wo = [el*1000 for el in ys_wo]
err_wo = [el*1000 for el in err_wo]
x_ro = [numClients(1, 2, el) for el in x_ro]
x_wo = [numClients(1, 2, el) for el in x_wo]
xs = [x_ro, x_wo]
ys = [ys_ro, ys_wo]
err = [err_ro, err_wo]
plot_generic(xs, ys, err, 
             title='Average Client Response Time', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=['Read only', 'Write only'],
             xticks=[2, 4,6, 8, 12, 24, 64], 
             save_file='2_2_latency.eps')


# In[10]:


# READ ONLY
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_1a', 'mwThroughput')
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
xticks = [6, 18, 36, 192]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonAllWorkers('3_1a', 'memtierThroughput')
print(xs_m)
print(ys_m)
plot_generic(xs, ys, stddevs, 
             ymax=16000, 
             title='Section 3.1 Cumulative Middleware Throughput, Read only',
             xlabel='Number of Clients', 
             ylabel='Throughput [requests / second]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_1a_throughputMiddleware.eps')
xs, ys, errs, labels = getDataFromJsonAllWorkers('3_1a', 'mwLatency')
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
ys = [[nsToMs(el) for el in y] for y in ys]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonAllWorkers('3_1a', 'memtierLatency')
print(xs_m)
print(ys_m)
errs = [[nsToMs(el) for el in err] for err in errs]
plot_generic(xs, ys, errs, 
             ymax=70,
             title='Section 3.1 Average Middleware Response Time, Read only', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_1a_latencyMiddleware.eps')

for w in ['8','16','32','64','128']:
    xs, ys, errs, labels = getDataFromJsonAdditionalMWPlot('3_1a', w)
    if w is '8':
        print(xs)
        print(ys)
    xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
    plot_generic(xs, ys, errs, 
                 ymax=70, 
                 title='', 
                 xlabel='Number of Clients', 
                 ylabel='Time [ms]', 
                 labels=labels, 
                 xticks=xticks,
                 save_file='3_1a_extendedLatencyMiddleware_{}w.eps'.format(w))

# WRITE ONLY
xs, ys, stddevs, labels = getDataFromJsonSpecificWorkers('3_1b', 'mwThroughput', ['8','16','32','64','128'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
xticks = xs[0]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonSpecificWorkers('3_1b', 'memtierThroughput', ['8','16','32','64','128'])
print(xs_m)
print(ys_m)
plot_generic(xs, ys, stddevs, 
             ymax=16000,
             title='Section 3.1 Cumulative Middleware Throughput, Write only', 
             xlabel='Number of Clients', ylabel='Throughput [requests / second]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_1b_throughputMiddleware.eps')

xs, ys, errs, labels = getDataFromJsonSpecificWorkers('3_1b', 'mwLatency', ['8','16','32','64','128'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
ys = [[nsToMs(el) for el in y] for y in ys]
errs = [[nsToMs(el) for el in err] for err in errs]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonSpecificWorkers('3_1b', 'memtierLatency', ['8','16','32','64','128'])
print(xs_m)
print(ys_m)
plot_generic(xs, ys, errs, 
             ymax=70,
             title='Section 3.1 Average Middleware Response Time, Write only', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_1b_latencyMiddleware.eps')

for w in ['8','16','32','64','128']:
    xs, ys, errs, labels = getDataFromJsonAdditionalMWPlot('3_1b', w)
    xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
    if w is '64':
        print(xs)
        print(ys)
    plot_generic(xs, ys, errs, 
                 ymax=70,
                 title='', 
                 xlabel='Number of Clients', 
                 ylabel='Time [ms]', 
                 labels=labels, 
                 xticks=xticks,
                 save_file='3_1b_extendedLatencyMiddleware_{}w.eps'.format(w))


# In[2]:


# sec3.2 READ ONLY
xs, ys, stddevs, labels = getDataFromJsonAllWorkers('3_2a', 'mwThroughput')
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
xticks = [6, 18, 36, 192]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonAllWorkers('3_2a', 'memtierThroughput')
print(xs_m)
print(ys_m)
plot_generic(xs, ys, stddevs, 
             ymax=16000, 
             title='Section 3.2 Cumulative Client Throughput, Read only', 
             xlabel='Number of Clients', ylabel='Throughput [requests / second]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_2a_throughputMiddleware.eps')
xs, ys, errs, labels = getDataFromJsonAllWorkers('3_2a', 'mwLatency')
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
ys = [[nsToMs(el) for el in y] for y in ys]
errs = [[nsToMs(el) for el in err] for err in errs]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonAllWorkers('3_2a', 'memtierLatency')
print(xs_m)
print(ys_m)
plot_generic(xs, ys, errs, 
             ymax=70, 
             title='Section 3.2 Average Client Response Time, Read only', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_2a_latencyMiddleware.eps')

for w in ['8','16','32','64','128']:
    xs, ys, errs, labels = getDataFromJsonAdditionalMWPlot('3_2a', w)
    xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
    if w is '8':
        print(xs)
        print(ys)
    plot_generic(xs, ys, errs, 
                 ymax=70, 
                 title='', 
                 xlabel='Number of Clients', 
                 ylabel='Time [ms]', 
                 labels=labels, 
                 xticks=xticks,
                 save_file='3_2a_extendedLatencyMiddleware_{}w.eps'.format(w))


# sec3.2 WRITE ONLY
xs, ys, stddevs, labels = getDataFromJsonSpecificWorkers('3_2b', 'mwThroughput', ['8','16','32','64', '128'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
xticks = xs[0]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonSpecificWorkers('3_2b', 'memtierThroughput', ['8','16','32','64', '128'])
print(xs_m)
print(ys_m)
plot_generic(xs, ys, stddevs, 
             ymax=16000, 
             title='Section 3.2 Cumulative Client Throughput, Write only', 
             xlabel='Number of Clients', 
             ylabel='Throughput [requests / second]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_2b_throughputMiddleware.eps')
xs, ys, errs, labels = getDataFromJsonSpecificWorkers('3_2b', 'mwLatency', ['8','16','32','64', '128'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
ys = [[nsToMs(el) for el in y] for y in ys]
errs = [[nsToMs(el) for el in err] for err in errs]
print(xs)
print(ys)
xs_m, ys_m, _, _ = getDataFromJsonSpecificWorkers('3_2b', 'memtierLatency', ['8','16','32','64','128'])
print(xs_m)
print(ys_m)
plot_generic(xs, ys, errs, 
             ymax=70, 
             title='Section 3.2 Average Client Response Time, Write only', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels, 
             xticks=xticks,
             save_file='3_2b_latencyMiddleware.eps')

for w in ['8','16','32','64','128']:
    xs, ys, errs, labels = getDataFromJsonAdditionalMWPlot('3_2b', w)
    xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
    if w is '64':
        print(xs)
        print(ys)
    plot_generic(xs, ys, errs, 
                 ymax=70, 
                 title='', 
                 xlabel='Number of Clients', 
                 ylabel='Time [ms]', 
                 labels=labels, 
                 xticks=xticks,
                 save_file='3_2b_extendedLatencyMiddleware_{}w.eps'.format(w))



# In[20]:


def removeLastKValues(values, k):
    return [el[:-k] for el in values]

# sec 4 WRITE ONLY
xs, ys, stddevs, labels = getDataFromJsonSpecificWorkers('4b', 'mwThroughput', ['8','16','32','64'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
xs = removeLastKValues(xs, 2)
ys = removeLastKValues(ys, 2)
stddevs = removeLastKValues(stddevs, 2)
#xticks = [6, 36, 72, 120, 192, 384, 768]
xticks = [0, 6, 36, 72, 120, 192]
print(xs)
print(ys)
print('memtier')
xs_mt, ys_mt, stddevs_mt, labels_mt = getDataFromJsonSpecificWorkers('4b', 'memtierThroughput', ['8','16','32','64'])
print(xs_mt)
print(ys_mt)
plot_generic(xs, ys, stddevs, 
             ymax=16000,
             title='Section 4 Cumulative Client Throughput, Write only', 
             xlabel='Number of Clients', 
             ylabel='Throughput [requests / second]', 
             labels=labels, 
             xticks=xticks,
             save_file='4b_throughputMiddleware.eps')
xs, ys, errs, labels = getDataFromJsonSpecificWorkers('4b', 'mwLatency', ['8','16','32','64'])
xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
ys = [[nsToMs(el) for el in y] for y in ys]
errs = [[nsToMs(el) for el in err] for err in errs]
xs = removeLastKValues(xs, 2)
ys = removeLastKValues(ys, 2)
errs = removeLastKValues(errs, 2)
print(xs)
print(ys)
plot_generic(xs, ys, errs, 
             ymax=70,
             title='Section 4 Average Client Response Time, Write only', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels, 
             xticks=xticks,
             save_file='4b_latencyMiddleware.eps')

for w in ['8','16','32','64']:
    xs, ys, errs, labels = getDataFromJsonAdditionalMWPlot('4b', w)
    xs = [[numClients(3, 2, el) for el in xs_] for xs_ in xs]
    xs = removeLastKValues(xs, 2)
    ys = removeLastKValues(ys, 2)
    errs = removeLastKValues(errs, 2)

    plot_generic(xs, ys, errs, 
                 ymax=70,
                 title='', 
                 xlabel='Number of Clients', 
                 ylabel='Time [ms]', 
                 labels=labels, 
                 xticks=xticks,
                 save_file='4b_extendedLatencyMiddleware_{}w.eps'.format(w))


# In[10]:


# SECTION 5 SHARDED
xs, ys, stddevs = getDataFromJsonAllKeys('5c', 'memtierThroughput')
plot_generic(xs, ys, stddevs, title='Cumulative Client Throughput Multiget, Sharded', 
             xlabel='Number of Keys', 
             ylabel='Throughput [requests / second]', 
             labels='throughput', 
             save_file='5a_throughputMemtier.eps')

xs, ys, errs = getDataFromJsonAllKeys('5c', 'memtierLatency')
ys = [el*1000 for el in ys]
errs = [el*1000 for el in errs]
plot_generic(xs, ys, errs, title='Average Client Response Time Multiget, Sharded', 
             xlabel='Number of Keys', 
             ylabel='Response Time [ms]', 
             labels='response time', 
             save_file='5a_latencyMemtier.eps')


# In[11]:


# SECTION 5 NONSHARDED
xs, ys, stddevs = getDataFromJsonAllKeys('5d', 'memtierThroughput')
plot_generic(xs, ys, stddevs, 
             title='Cumulative Client Throughput Multiget, Nonsharded', 
             xlabel='Number of Clients', ylabel='Throughput [requests / second]', 
             labels='throughput', 
             save_file='5b_throughputMemtier.eps')

xs, ys, errs = getDataFromJsonAllKeys('5d', 'memtierLatency')
ys = [el*1000 for el in ys]
errs = [el*1000 for el in errs]
plot_generic(xs, ys, errs, 
             title='Average Client Response Time Multiget, Nonsharded', 
             xlabel='Number of Clients', ylabel='Response Time [ms]', 
             labels='response time', 
             save_file='5b_latencyMemtier.eps')


# In[25]:



zipf = zipfile.ZipFile('plots.zip', 'w', zipfile.ZIP_STORED)
zipdir('./plots', zipf)
zipf.close()
print('done')

