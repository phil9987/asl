import json
import os
from collections import defaultdict

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

def totalNumberRequests(requests):
    numRequests = 0
    for req in requests:
        numRequests += req.numRequests
    return numRequests

def avgResponseTime(requests):
    totalMiddlewareTimeSum = 0
    for req in requests:
        totalMiddlewareTimeSum += req.middlewareTimeSum
    return float(totalMiddlewareTimeSum) / float(totalNumberRequests(requests))

def totalNumberRequestsFromHistogram(histogram):
    numRequests = 0
    for entry in histogram:
        numRequests += entry.count
    return numRequests

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
    for entry in mergedRequests:
        print(entry)
    return mergedRequests

def mergeWorkerLogEntriesFrom2Middlewares(requests1, requests2):
    mergedRequests = []
    for req1, req2 in zip(requests1, requests2):
        req1.merge(req2)
        mergedRequests.append(req1)
    return mergedRequests

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

def writeToFile(elements, filename):
    with open(filename, 'w') as f:
        f.writelines([str(el) for el in elements])

def mergeLogsFor1Middleware(middlewareLogfileName, mergedFileName):
    requests, histogram = extractRequestsAndHistogram(middlewareLogfileName)
    print("numberRequests in requests log = {} \n numberRequests in histogram = {}".format(totalNumberRequests(requests), totalNumberRequestsFromHistogram(histogram)))
    mergedRequests = mergeWorkerLogEntries(requests)
    mergedHistogram = mergeHistogramLogEntries(histogram)
    writeToFile(mergedRequests + mergedHistogram, mergedFileName)
    print("--\n after merging:\n numberRequests in mergedRequests = {} \n numberRequests in mergedHistogram = {}".format(totalNumberRequests(mergedRequests), totalNumberRequestsFromHistogram(mergedHistogram)))

def mergeLogsFor2Middlewares(mw1LogfileName, mw2LogfileName, mergedFileName):
    merged1FileName = "./mergedRequests1.log"
    merged2FileName = "./mergedRequests2.log"
    mergeLogsFor1Middleware(mw1LogfileName, merged1FileName)
    mergeLogsFor1Middleware(mw2LogfileName, merged2FileName)
    requests1, histogram1 = extractRequestsAndHistogram(merged1FileName)
    requests2, histogram2 = extractRequestsAndHistogram(merged2FileName)
    mergedHistogram = mergeHistogramLogEntries(histogram1 + histogram2)
    mergedRequests = mergeWorkerLogEntriesFrom2Middlewares(requests1, requests2)
    writeToFile(mergedRequests + mergedHistogram, mergedFileName)

def cutWarmupCooldown(requests, warmup, cooldown):
    return requests[warmup:len(requests)-cooldown]


def cumulativeThroughput(mergedFileName, startup, cooldown):
    requests, histogram = extractRequestsAndHistogram(mergedFileName)
    lenBefore = len(requests)
    requests = cutWarmupCooldown(requests, startup, cooldown)
    print("requests len {} after cut {}".format(lenBefore, len(requests)))
    totalNumRequests = totalNumberRequests(requests)
    avgResponseT = avgResponseTime(requests)
    print("total throughput: {} avgResponseTime: {}".format(totalNumRequests, avgResponseT))
    return totalNumRequests, avgResponseT


def main():
    #mergeLogsFor2Middlewares("./requests.log", "./requests_half.log", "./combined.log")
    #mergeLogsFor1Middleware("../../experiment_logs_18-11-2018_15-41-36/logSection3_1a/memtierCli32workerThreads64/run1/middleware1/requests.log","./combined_real64.log")
    totalNumRequests, avgResponseT = cumulativeThroughput("./combined_real64.log", 2, 3)

if __name__ == "__main__":
    main()