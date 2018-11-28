import json
import os
from collections import defaultdict

import statistics

from postprocessing_middleware import MWLogProc

class MemtierEntry:
    def __init__(self, splitting):
        # Second,SET Requests,SET Average Latency,SET Total Bytes,GET Requests,GET Average Latency,GET Total Bytes,GET Misses,GET Hits,WAIT Requests,WAIT Average Latency
        # 0,0,0.000000,0,322,0.003102,7379,322,0,0,0.000000
        self.timestamp = int(splitting[0])
        self.numSetRequests = int(splitting[1])
        self.avgSetLatency = float(splitting[2])
        self.numGetRequests = int(splitting[4])
        self.avgGetLatency = float(splitting[5])
        self.misses = int(splitting[7])
        self.hits = int(splitting[8])
        #print("new memtier entry: {}".format(self))

    def merge(self, otherEntry):    
        combinedNumSetRequests = float(self.numSetRequests + otherEntry.numSetRequests)
        if combinedNumSetRequests > 0:
            self.avgSetLatency = (self.avgSetLatency * float(self.numSetRequests) + otherEntry.avgSetLatency* float(otherEntry.numSetRequests)) / combinedNumSetRequests
        
        combinedNumGetRequests = float(self.numGetRequests + otherEntry.numGetRequests)
        if combinedNumGetRequests > 0:
            numerator=(self.avgGetLatency * float(self.numGetRequests) + otherEntry.avgGetLatency* float(otherEntry.numGetRequests))
            self.avgGetLatency = numerator / combinedNumGetRequests
        
        self.numSetRequests += otherEntry.numSetRequests
        self.numGetRequests += otherEntry.numGetRequests
        self.misses += otherEntry.misses
        self.hits += otherEntry.hits

    def __str__(self):
        return "{} {} {} {} {} {} {}\n".format(
            self.timestamp,
            self.numSetRequests,
            self.avgSetLatency,
            self.numGetRequests,
            self.avgGetLatency,
            self.misses,
            self.hits)

class HistogramEntry:
    def __init__(self, splitting, totalNumRequests):
        self.totalNumRequests = totalNumRequests
        self.latency = float(splitting[0]) # in ms
        self.percentage = float(splitting[1])
        self.numRequests = self.totalNumRequests*self.percentage

    def merge(self, histoEntry):
        self.totalNumRequests += histoEntry.totalNumRequests
        self.numRequests += histoEntry.numRequests
        self.percentage = (self.numRequests * 100.0) / self.totalNumRequests

    def __str__(self):
        return "{} {} {} {}\n".format(self. latency, self.numRequests, self.percentage, self.totalNumRequests)


def extractRequestsAndHistogram(logfilename):
    requests = []
    histogramGet = []
    histogramSet = []
    #print("extracting data from {}".format(logfilename))
    with open(logfilename) as f:
        mode=0   # 0 for requests, 1 for histogramGet, 2 for histogramSet
        skipCount=2
        totalNumGetRequests=0
        totalNumSetRequests=0
        for line in f:
            line = line.strip()
            if not line:
                # line is empty, next section begins
                mode += 1
                skipCount=2 # skip next 2 lines
                continue
            if skipCount > 0:
                skipCount -=1
                continue
            splitting = line.split(',')
            if mode == 0:
                # extracting requests
                req = MemtierEntry(splitting)
                totalNumSetRequests += req.numSetRequests
                totalNumGetRequests += req.numGetRequests
                requests.append(req)
            elif mode == 1:
                # extract histogramGet
                histogramGet.append(HistogramEntry(splitting, totalNumGetRequests))
            else:
                # extract histogramSet
                histogramSet.append(HistogramEntry(splitting, totalNumSetRequests))
    requests.sort(key=lambda r: r.timestamp)
    histogramGet.sort(key=lambda h: h.latency)
    histogramSet.sort(key=lambda h: h.latency)
    return requests, histogramGet, histogramSet

# TODO: set latency to the same format as in middlewarelogs
def setNumRequestsForHistogram(histogram):
    prevAmount = 0
    for h in histogram:
        thisAmount = int(h.numRequests)
        h.numRequests = thisAmount = prevAmount
        prevAmount = thisAmount

    # for testing purposes
    totalNumRequestscalc = 0
    for h in histogram:
        totalNumRequestcalc += h.numRequests
    totalNumRequests = 0
    if len(histogram) > 0:
        totalNumRequests = histogram[0].totalNumRequests
    print("totalNumRequests stored={} totalNumRequests calculated={}".format(totalNumRequests, totalNumRequestscalc))


def numSetRequests(requests):
    numReq = 0
    for req in requests:
        numReq += req.numSetRequests
    return numReq

def numGetRequests(requests):
    numReq = 0
    for req in requests:
        numReq += req.numGetRequests
    return numReq

def totalNumberRequests(requests):
    return numGetRequests(requests) + numSetRequests(requests)

def avgSetLatency(requests):
    totalNumSetRequests = numSetRequests(requests)
    if totalNumSetRequests == 0:
        return 0.0
    totalLatency = 0.0
    for req in requests:
        totalLatency += (req.avgSetLatency * req.numSetRequests)
    return totalLatency / totalNumSetRequests

def avgGetLatency(requests):
    totalNumGetRequests = numGetRequests(requests)
    if totalNumGetRequests == 0:
        return 0.0
    totalLatency = 0
    for req in requests:
        totalLatency += (req.avgGetLatency * req.numGetRequests)
    return totalLatency / totalNumGetRequests


def mergeLogsFrom2Clients(requests1, requests2):
    mergedRequests = []
    for req1, req2 in zip(requests1, requests2):
        req1.merge(req2)
        mergedRequests.append(req1)
    return mergedRequests

# TODO: not tested yet
def mergeHistogramLogEntries(histograms):
    mergerDict = defaultdict(list)
    mergedHistogram = []
    for histo in histograms:
        mergerDict[histo.latency].append(histo)
    for _, histogramsToMerge in mergerDict.items():
        tmpHisto, *tail = histogramsToMerge
        for histo in tail:
            tmpHisto.merge(histo)
        mergedHistogram.append(tmpHisto)
    mergedHistogram.sort(key = lambda histo: histo.latency)
    return mergedHistogram

def cutWarmupCooldown(requests, warmup, cooldown):
    return requests[warmup:len(requests)-cooldown]


def cumulativeThroughput(requests, startup, cooldown):
    requests = cutWarmupCooldown(requests, startup, cooldown)
    numGetRequestsPerSecond = numGetRequests(requests)
    numSetRequestsPerSecond = numSetRequests(requests)
    if len(requests) > 0:
        numGetRequestsPerSecond = numGetRequestsPerSecond / len(requests)
        numSetRequestsPerSecond = numSetRequestsPerSecond/ len(requests)
    avgLatencyGET = avgGetLatency(requests)
    avgLatencySET = avgSetLatency(requests)
    return numGetRequestsPerSecond, avgLatencyGET, numSetRequestsPerSecond, avgLatencySET

def writeToFile(elements, filename):
    with open(filename, 'w') as f:
        f.writelines([str(el) for el in elements])

def writePlotFile(elements, filename):
    with open(filename, 'w') as f:
        for el in elements:
            f.write("{} ".format(el))

def writeGnuplotFile(title, rows, filename):
    print("writing gnuplotfile to {}".format(filename))
    with open(filename, 'w') as f:
        f.write("#{}\n".format(title))
        for row in rows:
            f.write("{} {} {}\n".format(row[0], row[1], row[2]))


def readStatsData(fullpathtofile):
    meanNumReq = 0.0
    stddevNumReq = 0.0
    meanAvgLatency = 0.0
    stddevAvgLatency = 0.0
    mwMeanThroughput = 0.0
    mwStddevThroughput = 0.0
    mwMeanLatency = 0.0
    mwStddevLatency = 0.0
    with open(fullpathtofile, 'r') as f:
        skipLine = True
        for line in f:
            if skipLine:
                # skip header line
                skipLine = False
                continue
            splitting = line.split(' ')
            meanNumReq = float(splitting[0])
            stddevNumReq = float(splitting[1])
            meanAvgLatency = float(splitting[2])
            stddevAvgLatency = float(splitting[3])
            mwMeanThroughput = float(splitting[4])
            mwStddevThroughput = float(splitting[5])
            mwMeanLatency = float(splitting[6])
            mwStddevLatency = float(splitting[6])
    return meanNumReq, stddevNumReq, meanAvgLatency, stddevAvgLatency, mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency

def mergeLogsFor1Client(clientFolder):
    requests = []
    histogramGet = []
    histogramSet = []
    #print("merging logs for client {}".format(clientFolder))
    #print(os.listdir(clientFolder))
    for filename in os.listdir(clientFolder):
        #print('.')
        if filename.endswith(".csv") and filename.startswith('client'):
            tmpRequests, tmpHistogramGet, tmpHistogramSet = extractRequestsAndHistogram(os.path.join(clientFolder, filename))
            #print("number requests for {}: {}".format(filename, totalNumberRequests(tmpRequests)))
            if len(requests) == 0:
                requests = tmpRequests
                histogramGet = tmpHistogramGet
                histogramSet = tmpHistogramSet
            else:
                mergeLogsFrom2Clients(requests, tmpRequests)
    #print("Total number of requests after merging: {}".format(totalNumberRequests(requests)))
    return requests, histogramGet, histogramSet

def mergeLogsFor3Clients(client1Folder, client2Folder, client3Folder):
    requests1, _, _ = mergeLogsFor1Client(client1Folder)
    requests2, _, _ = mergeLogsFor1Client(client2Folder)
    requests3, _, _ = mergeLogsFor1Client(client3Folder)
    if len(requests1) == 0:
        print("ERROR: no requests for {}".format(client1Folder))
    if len(requests2) == 0:
        print("ERROR: no requests for {}".format(client2Folder))
    if len(requests3) == 0:
        print("ERROR: no requests for {}".format(client3Folder))
    mergedRequests = mergeLogsFrom2Clients(requests1, requests2)
    mergedRequests = mergeLogsFrom2Clients(mergedRequests, requests3)
    return cumulativeThroughput(mergedRequests, 3, 3)

def mergeMemtierLogs(basefolder, clientFolders):
    numClients = len(clientFolders)
    avgNumGetPerSec = 0
    avgLatencyGET = 0.0
    avgNumSetPerSec = 0
    avgLatencySET = 0.0
    if numClients == 1:
        requests, _, _ = mergeLogsFor1Client(os.path.join(basefolder, clientFolders[0]))
        if len(requests) == 0:
            print("ERROR: no requests for {}".format(os.path.join(basefolder, clientFolders[0])))
        avgNumGetPerSec, avgLatencyGET, avgNumSetPerSec, avgLatencySET = cumulativeThroughput(requests, 3, 3)
    elif numClients == 3:
        avgNumGetPerSec, avgLatencyGET, avgNumSetPerSec, avgLatencySET = mergeLogsFor3Clients(os.path.join(basefolder, clientFolders[0]),
                                os.path.join(basefolder, clientFolders[1]),
                                os.path.join(basefolder, clientFolders[2]))
    else:
        print("ERROR: found {} client directories, no implementation for this yet. clientFolders: {}".format(numClients, clientFolders))
    return avgNumGetPerSec, avgLatencyGET, avgNumSetPerSec, avgLatencySET

def getFolders(fullPath, startingTerm):
    matchingFolders = []
    for f in os.listdir(fullPath):
        if os.path.isdir(os.path.join(fullPath, f)) and f.startswith(startingTerm):
            matchingFolders.append(f)
    return matchingFolders

def getClientFolders(fullFolderPath):
    return getFolders(fullFolderPath, 'client')

def getMiddlewareFolders(fullFolderPath):
    return getFolders(fullFolderPath, 'middleware')


def calcMeanAndStdDeviation(data):
    return statistics.mean(data), statistics.pstdev(data)

def calcStats(basefolder):
    for secDir in os.listdir(basefolder):
        fullPathSecDir = os.path.join(basefolder, secDir)
        if os.path.isdir(fullPathSecDir):
            print("found section directory: {}".format(secDir))
            mode = ''
            if secDir.endswith('a'):
                # this is a READ only experiment for sections 2 and 3
                mode = 'READ'
            elif secDir.endswith('b'):
                # this is a WRITE only experiment for sections 2 and 3
                mode = 'WRITE'
            elif secDir.startswith('init'):
                continue
            else:
                print("ERROR: Mode could not be detected for folder {}".format(secDir))
            for paramDir in os.listdir(fullPathSecDir):
                fullPathParamDir = os.path.join(fullPathSecDir, paramDir)
                if os.path.isdir(fullPathParamDir):
                    print("found param directory: {}".format(paramDir))
                    memtierThroughputOverall = []
                    memtierLatencyOverall = []
                    mwThroughputOverall = []
                    mwLatencyOverall = []
                    for runDir in os.listdir(fullPathParamDir):
                        fullPathRunDir = os.path.join(fullPathParamDir, runDir)
                        if os.path.isdir(fullPathRunDir):
                            clientFolders = getClientFolders(fullPathRunDir)
                            middlewareFolders = getMiddlewareFolders(fullPathRunDir)
                            numClients = len(clientFolders)
                            numMiddlewares = len(middlewareFolders)
                            print("found run directory: {} with {} clients and {} middlewares".format(runDir, numClients, numMiddlewares))
                            avgNumGetPerSec, avgLatencyGET, avgNumSetPerSec, avgLatencySET = mergeMemtierLogs(fullPathRunDir, clientFolders)
                            if mode == 'READ':
                                memtierThroughputOverall.append(avgNumGetPerSec)
                                memtierLatencyOverall.append(avgLatencyGET)
                            elif mode == 'WRITE':
                                memtierThroughputOverall.append(avgNumSetPerSec)
                                memtierLatencyOverall.append(avgLatencySET)
                            else:
                                print("ERROR: mode {} not implemented yet".format(mode))

                            mwproc = MWLogProc(fullPathRunDir, middlewareFolders, 3, 3)
                            mwThroughput, mwLatency = mwproc.calcStatistics()
                            mwThroughputOverall.append(mwThroughput)
                            mwLatencyOverall.append(mwLatency)

                    meanThroughputMemtier = 0.0
                    stddevThroughputMemtier = 0.0
                    meanLatencyMemtier = 0.0
                    stddevLatencyMemtier = 0.0
                    meanThroughputMemtier, stddevThroughputMemtier = calcMeanAndStdDeviation(memtierThroughputOverall)
                    meanLatencyMemtier, stddevLatencyMemtier = calcMeanAndStdDeviation(memtierLatencyOverall)

                    ### middleware logs
                    meanMWThroughput, stddevMWThroughput = calcMeanAndStdDeviation(mwThroughputOverall)
                    meanMWLatency, stddevMWLatency = calcMeanAndStdDeviation(mwLatencyOverall)
                    data = 'memtier_meanThroughput memtier_stddevThroughput memtier_meanAvgLatency memtier_stddevAvgLatency mw_meanThroughput mw_stddevThroughput mw_meanLatency mw_stddevLatency\n'
                    data += "{} {} {} {} {} {} {} {}".format(meanThroughputMemtier, stddevThroughputMemtier, 
                                                             meanLatencyMemtier, stddevLatencyMemtier, 
                                                             meanMWThroughput, stddevMWThroughput, 
                                                             meanMWLatency, stddevMWLatency)
                    writeToFile(data, os.path.join(fullPathParamDir, 'merged_stats.data'))

def extractMemtierParam(foldername):
    splitting = foldername.split('memtierCli')
    relevantPart = splitting[1]
    splitting = relevantPart.split('workerThreads')
    relevantPart = splitting[0]
    return int(relevantPart)

def extractWorkerThreadsParam(foldername):
    splitting = foldername.split('workerThreads')
    if len(splitting) == 1:
        # workerThreads is not contained in foldername
        return -1
    else:
        relevantPart = splitting[1]
        return int(relevantPart)

def extractSection(foldername):
    splitting = foldername.split('logSection')
    relevantPart = splitting[1]
    splitting = relevantPart.split('_')
    relevantPart = splitting[0]
    subsection = splitting[1]
    return int(relevantPart), subsection

def plotFilesForWorkerthreadDict(workerthreadDict, title, filename):
    print(workerthreadDict)
    for numWorkers, plotdata in workerthreadDict.items():
        filename_ = "{}_w{}.plotdata".format(filename, numWorkers)
        writeGnuplotFile(title, plotdata, filename_)


def createPlotFiles(basefolder, plotfolder):
    for secDir in os.listdir(basefolder):
            fullPathSecDir = os.path.join(basefolder, secDir)
            memtierThroughput = {}  # triple (#memtiercli, meanThroughput, stddev)
            memtierLatency = {}     # triple (#memtiercli, meanLatency, stddev)
            mwThroughput = {}       # triple (#memtiercli, meanThroughput, stddev)
            mwLatency = {}          # triple (#memtiercli, meanLatency, stddev)

            if os.path.isdir(fullPathSecDir):
                print("found section directory: {}".format(secDir))
                if secDir.startswith('init'):
                    continue
                section, subsection = extractSection(secDir)
                for paramDir in os.listdir(fullPathSecDir):
                    fullPathParamDir = os.path.join(fullPathSecDir, paramDir)
                    if os.path.isdir(fullPathParamDir):
                        memtierCliParam = extractMemtierParam(paramDir)
                        workerThreadsParam = extractWorkerThreadsParam(paramDir)
                        print("found param directory: {} with memtierCli={} and workerThreads={}".format(paramDir, memtierCliParam, workerThreadsParam))
                        memtierMeanThroughput, memtierStddevThroughput, memtierMeanLatency, memtierStddevLatency, mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency = readStatsData(os.path.join(fullPathParamDir, 'merged_stats.data'))
                        memtierThroughput.setdefault(workerThreadsParam, [])
                        memtierThroughput[workerThreadsParam].append((memtierCliParam, memtierMeanThroughput, memtierStddevThroughput))
                        memtierLatency.setdefault(workerThreadsParam, [])
                        memtierLatency[workerThreadsParam].append((memtierCliParam, memtierMeanLatency, memtierStddevLatency))
                        mwThroughput.setdefault(workerThreadsParam, [])
                        mwThroughput[workerThreadsParam].append((memtierCliParam, mwMeanThroughput, mwStddevThroughput))
                        mwLatency.setdefault(workerThreadsParam, [])
                        mwLatency[workerThreadsParam].append((memtierCliParam, mwMeanLatency, mwStddevLatency))
                #plotFilesForWorkerthreadDict(memtierThroughput, "numMemtierClients meanThroughput stddev", os.path.join(plotfolder, "{}_memtierThroughput".format(secDir)))
                #plotFilesForWorkerthreadDict(memtierLatency, "numMemtierClients meanLatency stddev", os.path.join(plotfolder,"{}_memtierLatency".format(secDir)))
                #plotFilesForWorkerthreadDict(mwThroughput, "numMemtierClients meanThroughput stddev", os.path.join(plotfolder,"{}_mwThroughput".format(secDir)))
                #plotFilesForWorkerthreadDict(mwLatency, "numMemtierClients meanLatency stddev", os.path.join(plotfolder,"{}_mwLatency".format(secDir)))

                jsondata = {}
                jsondata['memtierThroughput'] = memtierThroughput
                jsondata['memtierLatency'] = memtierLatency
                jsondata['mwThroughput'] = mwThroughput
                jsondata['mwLatency'] = mwLatency
                json.dump(jsondata, open(os.path.join(plotfolder, "{}.plotdata".format(secDir)), 'w'))

def main():
    basefolder = 'C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/logs_sec2_sec3_22112018/experiment_logs_20-11-2018_22-22-23'
    plotfolder = 'C:/Users/philip/Programming/AdvancedSystemsLab/Programming/aggregated_avg/'
    calcStats(basefolder)
    createPlotFiles(basefolder, plotfolder)





if __name__ == "__main__":
    main()