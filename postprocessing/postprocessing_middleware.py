import json
import os
from collections import defaultdict

class MWLogProc:

    def __init__(self, basepath, middlewareFolders, warmup, cooldown):
        self.basepath = basepath
        if len(middlewareFolders) == 0:
            # no middleware logs...
            self.nothing = True
        else:
            self.nothing = False
            logpath1 = os.path.join(basepath, middlewareFolders[0], 'requests.log')
            if len(middlewareFolders) == 1:
                self.requests, self.histogramGet, self.histogramSet = self.mergeLogsFor1Middleware(logpath1)
            else:
                logpath2 = os.path.join(basepath, middlewareFolders[1], 'requests.log')
                self.requests, self.histogramGet, self.histogramSet = self.mergeLogsFor2Middlewares(logpath1, logpath2)
            self.cutWarmupCooldown(warmup, cooldown)

    @staticmethod
    def extractRequestsAndHistogram(logfilename):
        requests = []
        histogramSet = []
        histogramGet = []
        with open(logfilename) as f:
            for line in f:
                current_line = line.split(' ')
                if current_line[1].startswith("HISTOGRAM_GET"):
                    histogramGet.append(HistogramEntry(current_line))
                elif current_line[1].startswith("HISTOGRAM_SET"):
                    histogramSet.append(HistogramEntry(current_line))
                else:
                    requests.append(RequestEntry(current_line))
        return requests, histogramGet, histogramSet

    @staticmethod
    def totalNumberRequests(requests):
        numRequests = 0
        for req in requests:
            numRequests += req.numRequests
        return numRequests

    def avgResponseTime(self):
        totalMiddlewareTimeSum = 0
        for req in self.requests:
            totalMiddlewareTimeSum += req.middlewareTimeSum
        return float(totalMiddlewareTimeSum) / float(MWLogProc.totalNumberRequests(self.requests))

    def avgQueueTime(self):
        totalQueueTimeSum = 0
        for req in self.requests:
            totalQueueTimeSum += req.queueWaitingTimeSum
        return float(totalQueueTimeSum) / float(MWLogProc.totalNumberRequests(self.requests))
    
    def avgServiceTime(self):
        totalServiceTimeSum = 0
        for req in self.requests:
            totalServiceTimeSum += req.serverTimeSum
        return float(totalServiceTimeSum) / float(MWLogProc.totalNumberRequests(self.requests))

    def avgQueueLength(self):
        totalQueueLengthSum = 0
        for req in self.requests:
            totalQueueLengthSum += req.queueLengthSum
        return totalQueueLengthSum / MWLogProc.totalNumberRequests(self.requests)

    def calcStatistics(self):
        if self.nothing:
            return -1, -1, -1, -1, -1
        numReqPerSec = 0.0
        if len(self.requests) > 0:
            numReqPerSec = MWLogProc.totalNumberRequests(self.requests)/len(self.requests)
        else:
            print("ERROR MW postprocessing: no requests for {}".format(self.basepath))
        return numReqPerSec, self.avgResponseTime(), self.avgQueueTime(), self.avgServiceTime(), self.avgQueueLength()

    @staticmethod
    def totalNumberRequestsFromHistogram(histogram):
        numRequests = 0
        for entry in histogram:
            numRequests += entry.numRequests
        return numRequests

    @staticmethod
    def mergeWorkerLogEntries(requests):
        mergerDict = defaultdict(list)
        mergedRequests = []
        for request in requests:
            mergerDict[request.periodStart].append(request)
        for _, requestsToMerge in mergerDict.items():
            tmpReq, *tail = requestsToMerge
            for req in tail:
                tmpReq.merge(req)
            mergedRequests.append(tmpReq)
        mergedRequests.sort(key = lambda req: req.periodStart)
        return mergedRequests

    @staticmethod
    def mergeWorkerLogEntriesFrom2Middlewares(requests1, requests2):
        mergedRequests = []
        for req1, req2 in zip(requests1, requests2):
            req1.merge(req2)
            mergedRequests.append(req1)
        return mergedRequests

    @staticmethod
    def mergeHistogramLogEntries(histograms):
        mergerDict = defaultdict(list)
        mergedHistogram = []
        for histoEntry in histograms:
            mergerDict[histoEntry.responseTime].append(histoEntry)
        for _, histogramEntriesToMerge in mergerDict.items():
            tmpHistoEntry, *tail = histogramEntriesToMerge
            for histo in tail:
                tmpHistoEntry.merge(histo)
            mergedHistogram.append(tmpHistoEntry)
        mergedHistogram.sort(key = lambda histo: histo.responseTime)
        return mergedHistogram

    @staticmethod
    def writeToFile(elements, filename):
        with open(filename, 'w') as f:
            f.writelines([str(el) for el in elements])

    @staticmethod
    def mergeLogsFor1Middleware(middlewareLogfileName):
        requests, histogramGet, histogramSet = MWLogProc.extractRequestsAndHistogram(middlewareLogfileName)
        mergedRequests = MWLogProc.mergeWorkerLogEntries(requests)
        mergedHistogramGet = MWLogProc.mergeHistogramLogEntries(histogramGet)
        mergedHistogramSet = MWLogProc.mergeHistogramLogEntries(histogramSet)
        return mergedRequests, mergedHistogramGet, mergedHistogramSet

    @staticmethod
    def mergeLogsFor2Middlewares(mw1LogfileName, mw2LogfileName):
        requests1, histogram1Get, histogram1Set = MWLogProc.mergeLogsFor1Middleware(mw1LogfileName)
        requests2, histogram2Get, histogram2Set = MWLogProc.mergeLogsFor1Middleware(mw2LogfileName)
        mergedHistogramGet = MWLogProc.mergeHistogramLogEntries(histogram1Get + histogram2Get)
        mergedHistogramSet = MWLogProc.mergeHistogramLogEntries(histogram1Set + histogram2Set)
        mergedRequests = MWLogProc.mergeWorkerLogEntriesFrom2Middlewares(requests1, requests2)
        return mergedRequests, mergedHistogramGet, mergedHistogramSet

    def cutWarmupCooldown(self, warmup, cooldown):
        lenBefore = len(self.requests)
        self.requests = self.requests[warmup:len(self.requests)-cooldown]
        #print("Cut warmup and cooldown from requests. Before: {} after: {}".format(lenBefore, len(self.requests)))

class RequestEntry:
    def __init__(self, splitting):
        self.timestamp = splitting[0]
        self.periodStart = int(splitting[1])
        self.workerId = int(splitting[2])
        self.queueLengthSum = int(splitting[3])
        self.queueWaitingTimeSum = int(splitting[4])
        self.serverTimeSum = int(splitting[5])
        self.middlewareTimeSum = int(splitting[6])
        self.numMissesSum = int(splitting[7])
        self.numMultigetKeysSum = int(splitting[8])
        self.numGetRequests = int(splitting[9])
        self.numMultigetRequests = int(splitting[10])
        self.numSetRequests = int(splitting[11])
        self.numRequests = int(splitting[12])
        self.server1Count = int(splitting[13])
        self.server2Count = int(splitting[14])
        self.server3Count = int(splitting[15])

    def merge(self, req):
        self.workerId = -1
        self.queueLengthSum += req.queueLengthSum
        self.queueWaitingTimeSum += req.queueWaitingTimeSum
        self.serverTimeSum += req.serverTimeSum
        self.middlewareTimeSum += req.middlewareTimeSum
        self.numMissesSum += req.numMissesSum
        self.numMultigetKeysSum += req.numMultigetKeysSum
        self.numGetRequests += req.numGetRequests
        self.numMultigetRequests += req.numMultigetRequests
        self.numSetRequests += req.numSetRequests
        self.numRequests += req.numRequests
        self.server1Count += req.server1Count
        self.server2Count += req.server2Count
        self.server3Count += req.server3Count

    def __str__(self):
        return "{} {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}\n".format(
            self.timestamp,     # just put a timestamp, we won't need it anyway
            self.periodStart,
            -1,                 # placeholder for not needed workerThreadId 
            self.queueLengthSum,
            self.queueWaitingTimeSum,
            self.serverTimeSum,
            self.middlewareTimeSum,
            self.numMissesSum,
            self.numMultigetKeysSum,
            self.numGetRequests,
            self.numMultigetRequests,
            self.numSetRequests,
            self.numRequests,
            self.server1Count,
            self.server2Count,
            self.server3Count)

class HistogramEntry:
    def __init__(self, splitting):
        self.timestamp = splitting[0]
        self.description = splitting[1]
        self.responseTime = int(splitting[2])        # response time in 100us
        self.numRequests = int(splitting[3])               # number of requests that had this response time

    def merge(self, histogram):
        self.numRequests += histogram.numRequests

    def __str__(self):
        return "{} {} {} {}\n".format(self.timestamp, self.description, self.responseTime, self.numRequests)

def main():
    mwproc = MWLogProc("C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_03-12-2018_11-06-33/logSection3_1a/memtierCli1workerThreads8/run1", ["middleware1"], 3, 3)
    print(mwproc.calcStatistics())

if __name__ == "__main__":
    main()