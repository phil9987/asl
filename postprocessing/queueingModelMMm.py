import os
import pandas as pd
from postprocessing_memtier import readStatsData, writeToFile
import numpy as np
from matplotlib import pyplot as plt
import math

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
        for (x, y, label) in zip(xs, ys, labels):
            ax.plot(x, y, fmt, markersize=markersize, label=label)
            if ymax is None and y_tmp < max(y):
                y_tmp = max(y)
        if ymax is None:
            ymax = 1.1*y_tmp
        ax.set_ylim(bottom=0, top=ymax)
    
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
    #plt.show()
    plt.clf()

basefolder = 'C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_03-12-2018_11-06-33/logSection4b/'
clients = [1,3,6,12,20,32]
#workerServicerates = [(8,7284),(16,9268),(32,10821),(64,12566)] # (num worker threads, maxClientThroughput)
workerServicerates = [(8,7300),(16,9300),(32,10900),(64,12600)] # (num worker threads, maxClientThroughput)
output = []
queueLenObs = []
queueLenPred = []
responseTimeObs = []
responseTimePred = []
waitingTimeObs = []
waitingTimePred = []

for w, serviceRate in workerServicerates:
    columns = ['Clients', '$\lambda$', '$\rho$', '$E[r]$', '$E[n_q]$', '$E[w]$']
    # numClients, arrivalRate, serviceRate, responsetime, queueLen, waiting time
    dfWorker = pd.DataFrame(columns=columns)
    predictedResponseTimes = []
    observedResponseTimes = []
    predictedQueueLens = []
    observedQueueLens = []
    predictedWaitingTimes = []
    observedWaitingTimes = []
    m=w*2
    for cli in clients:
        folder = 'memtierCli{}workerThreads{}'.format(cli, w)
        meanClientThroughput, _, meanClientResponseTime, _, _, _, _, _, meanQueueLen, _, meanQueueTime, _, meanServiceTime, _ = readStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
        p = meanClientThroughput / (serviceRate)
        #serviceRate = serviceRate/m
        s = 0
        for i in range(1,m):
            s += math.pow(m*p, i) / math.factorial(i)
        zeroProb = 1/(1 + math.pow(m*p, m)/(math.factorial(m)*(1-p)) + s)
        queueProb = (math.pow(m*p, m)/(math.factorial(m)*(1-p))) * zeroProb
        print('zeroProb={} queueProb={} meanThroughput={} serviceRate={} traffic intensity = {}'.format(zeroProb, queueProb, meanClientThroughput, serviceRate, p))
        predictedResponseTime = (1/(serviceRate/m))*(1+queueProb/(m*(1-p)))*1000
        print("W{}C{} observed RT = {} predicted RT = {}".format(w, cli*6, meanClientResponseTime*1000, predictedResponseTime))
        predictedQueueLen = p*queueProb/(1-p)
        print("W{}C{} observed NQ = {} predicted NQ = {}".format(w, cli*6, meanQueueLen, predictedQueueLen))
        predictedWaitingTime = predictedQueueLen / meanClientThroughput
        print("W{}C{} observed w = {} predicted w = {}".format(w, cli*6, meanQueueTime, predictedWaitingTime))
        df = pd.DataFrame([[cli*6, meanClientThroughput, p, '{0:.2f} | {1:.2f}'.format(predictedResponseTime,meanClientResponseTime*1000), '{0:.2f} | {1:.2f}'.format(predictedQueueLen, meanQueueLen), '{0:.2f} | {1:.2f}'.format(predictedWaitingTime, meanQueueTime)]], columns=columns)
        dfWorker = dfWorker.append(df)
        predictedResponseTimes.append(predictedResponseTime)
        observedResponseTimes.append(meanClientResponseTime*1000)
        predictedQueueLens.append(predictedQueueLen)
        observedQueueLens.append(meanQueueLen)
        predictedWaitingTimes.append(predictedWaitingTime)
        observedWaitingTimes.append(meanQueueTime)
    queueLenObs.append(observedQueueLens)
    queueLenPred.append(predictedQueueLens)
    responseTimeObs.append(observedResponseTimes)
    responseTimePred.append(predictedResponseTimes)
    waitingTimeObs.append(observedWaitingTimes)
    waitingTimePred.append(predictedWaitingTimes)
    output.append("{}WORKERS--------------------\n".format(w))
    print(output[-1])
    pd.options.display.float_format = '{:.2f}'.format
    output.append(dfWorker.to_latex())
    print(output[-1])

writeToFile(output, './plots/MMmtables.tex')
labels = ['8 WT', '16 WT', '32 WT', '64 WT']
x = [el*6 for el in clients]
xs = [x, x, x, x]
plot_generic(xs, queueLenPred, 
             title='Predicted Queue Size', 
             xlabel='Number of Clients', 
             ylabel='Queue size', 
             labels=labels,
             xticks=x, 
             ymax=460,
             save_file='7_MMm_QueueSizePred.eps')
plot_generic(xs, queueLenObs, 
             title='Observed avg Queue Size', 
             xlabel='Number of Clients', 
             ylabel='Queue size', 
             labels=labels,
             xticks=x, 
             ymax=460,
             save_file='7_MMm_QueueSizeObserved.eps')

plot_generic(xs, responseTimeObs, 
             title='Observed Client Response Time', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels,
             xticks=x, 
             ymax=70,
             save_file='7_MMm_ResponseTimeObserved.eps')
plot_generic(xs, responseTimePred, 
             title='Predicted Client Response Time', 
             xlabel='Number of Clients', 
             ylabel='Response Time [ms]', 
             labels=labels,
             xticks=x, 
             ymax=70,
             save_file='7_MMm_ResponseTimePredicted.eps')

plot_generic(xs, waitingTimeObs, 
             title='Observed Queue Waiting Time', 
             xlabel='Number of Clients', 
             ylabel='Waiting Time [ms]', 
             labels=labels,
             xticks=x, 
             ymax=65,
             save_file='7_MMm_WaitingTimeObserved.eps')
plot_generic(xs, responseTimePred, 
             title='Predicted Queue Waiting Time', 
             xlabel='Number of Clients', 
             ylabel='Waiting Time [ms]', 
             labels=labels,
             xticks=x, 
             ymax=65,
             save_file='7_MMm_WaitingTimePredicted.eps')




    