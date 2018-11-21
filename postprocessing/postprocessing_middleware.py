import json
import os
from collections import defaultdict

class MWLogProc:

    def __init__(self, basepath, middlewareFolders):
        if len(middlewareFolders) == 0:
            # no middleware logs...
            self.nothing = True
        else:
            self.nothing = False
            logpath1 = os.path.join(basepath, middlewareFolders[0], 'requests.log')
            if len(middlewareFolders) == 1:
                self.requests, self.histogram = self.mergeLogsFor1Middleware(logpath1)
            else:
                logpath2 = os.path.join(basepath, middlewareFolders[1], 'requests.log')
                self.requests, self.histogram = self.mergeLogsFor2Middlewares(logpath1, logpath2)

    @staticmethod
    def extractRequestsAndHistogram(logfilename):
        requests = []
        histogram = []
        with open(logfilename) as f:
            for line in f:
                current_line = line.split(' ')
                if current_line[1].startswith("HISTOGRAM"):
                    histogram.append(HistogramEntry(current_line))
                else:
                    requests.append(RequestEntry(current_line))
        return requests, histogram

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

    def calcStatistics(self):
        if self.nothing:
            return -1, -1
        return MWLogProc.totalNumberRequests(self.requests), self.avgResponseTime()

    @staticmethod
    def totalNumberRequestsFromHistogram(histogram):
        numRequests = 0
        for entry in histogram:
            numRequests += entry.count
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
        for histo in histograms:
            mergerDict[histo.responseTime].append(histo)
        for _, histogramsToMerge in mergerDict.items():
            tmpHisto, *tail = histogramsToMerge
            for histo in tail:
                tmpHisto.merge(histo)
            mergedHistogram.append(tmpHisto)
        mergedHistogram.sort(key = lambda histo: histo.responseTime)
        return mergedHistogram

    @staticmethod
    def writeToFile(elements, filename):
        with open(filename, 'w') as f:
            f.writelines([str(el) for el in elements])

    @staticmethod
    def mergeLogsFor1Middleware(middlewareLogfileName):
        requests, histogram = MWLogProc.extractRequestsAndHistogram(middlewareLogfileName)
        print("numberRequests in requests log = {} \nnumberRequests in histogram = {}".format(MWLogProc.totalNumberRequests(requests), MWLogProc.totalNumberRequestsFromHistogram(histogram)))
        mergedRequests = MWLogProc.mergeWorkerLogEntries(requests)
        mergedHistogram = MWLogProc.mergeHistogramLogEntries(histogram)
        print("--\nafter merging:\nnumberRequests in mergedRequests = {} \nnumberRequests in mergedHistogram = {}".format(MWLogProc.totalNumberRequests(mergedRequests), MWLogProc.totalNumberRequestsFromHistogram(mergedHistogram)))
        return mergedRequests, mergedHistogram

    @staticmethod
    def mergeLogsFor2Middlewares(mw1LogfileName, mw2LogfileName):
        requests1, histogram1 = MWLogProc.mergeLogsFor1Middleware(mw1LogfileName)
        requests2, histogram2 = MWLogProc.mergeLogsFor1Middleware(mw2LogfileName)
        print("MW1: numberRequests in requests log = {} \nnumberRequests in histogram = {}".format(MWLogProc.totalNumberRequests(requests1), MWLogProc.totalNumberRequestsFromHistogram(histogram1)))
        print("MW2: numberRequests in requests log = {} \nnumberRequests in histogram = {}".format(MWLogProc.totalNumberRequests(requests2), MWLogProc.totalNumberRequestsFromHistogram(histogram2)))
        mergedHistogram = MWLogProc.mergeHistogramLogEntries(histogram1 + histogram2)
        mergedRequests = MWLogProc.mergeWorkerLogEntriesFrom2Middlewares(requests1, requests2)
        print("--\nafter merging:\n numberRequests in mergedRequests = {} \nnumberRequests in mergedHistogram = {}".format(MWLogProc.totalNumberRequests(mergedRequests), MWLogProc.totalNumberRequestsFromHistogram(mergedHistogram)))
        return mergedRequests, mergedHistogram

    def cutWarmupCooldown(self, warmup, cooldown):
        lenBefore = len(self.requests)
        self.requests = self.requests[warmup:len(self.requests)-cooldown]
        print("Cut warmup and cooldown from requests. Before: {} after: {}".format(lenBefore, len(self.requests)))


    def cumulativeThroughput(self):
        totalNumRequests = MWLogProc.totalNumberRequests(self.requests)
        avgResponseT = self.avgResponseTime()
        print("total throughput: {} avgResponseTime: {}".format(totalNumRequests, avgResponseT))
        return totalNumRequests, avgResponseT

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
        self.count = int(splitting[3])               # number of requests that had this response time

    def merge(self, histogram):
        self.count += histogram.count

    def __str__(self):
        return "{} {} {} {}\n".format(self.timestamp, "HISTOGRAM", self.responseTime, self.count)

def main():
    #mergeLogsFor2Middlewares("./requests.log", "./requests_half.log", "./combined.log")
    mwproc = MWLogProc(["C:/Users/phili/OneDrive - ETHZ/ETHZ/MSC/AdvancedSystemsLab/Programming/data/logs_sec2_sec3_22112018/experiment_logs_20-11-2018_22-22-23/logSection3_1a/memtierCli1workerThreads8/run1/middleware1/requests.log"])
    mwproc.cutWarmupCooldown(3,3)
    totalNumRequests, avgResponseT = mwproc.cumulativeThroughput()

if __name__ == "__main__":
    main()