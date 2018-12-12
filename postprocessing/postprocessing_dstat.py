import json
import os
from collections import defaultdict
from statistics import mean

class DstatProc:
    def __init__(self, basepath):
        self.basepath = basepath

    def mergeConfigurationAverages(self):
        for secDir in os.listdir(self.basepath):
            fullPathSecDir = os.path.join(self.basepath, secDir)
            if os.path.isdir(fullPathSecDir) and not secDir.startswith("init"):
                stats = defaultdict(lambda: defaultdict(list))
                for f in os.listdir(fullPathSecDir):
                    if f.endswith('.csv') and not f.startswith('overall'):
                        filetype=''
                        if f.startswith('client'):
                            filetype='client'
                        elif f.startswith('server'):
                            filetype='server'
                        elif f.startswith('middleware'):
                            filetype='middleware'
                        skip = 1
                        for line in open(os.path.join(fullPathSecDir, f), 'r'):
                            if skip > 0:
                                # skip header
                                print("skipping header:{}".format(line))
                                skip -= 1
                                continue
                            print(line)
                            splitting = line.split(',')
                            key = splitting[0]
                            stats[filetype][key].append(float(splitting[1]))
                            stats[filetype][key].append(float(splitting[2]))
                            stats[filetype][key].append(float(splitting[3]))
                            stats[filetype][key].append(float(splitting[4]))
                overallStats = defaultdict(lambda: defaultdict(list))
                filetypes = []
                for filetype, d in stats.items():
                    filetypes.append(filetype)
                    for key, l in d.items():
                        meanCpu = mean(l[::4])
                        meanMem = mean(l[1::4])
                        meanSend = mean(l[2::4])
                        meanRecv = mean(l[3::4])
                        overallStats[key][filetype].append(meanCpu)
                        overallStats[key][filetype].append(meanMem)
                        overallStats[key][filetype].append(meanSend)
                        overallStats[key][filetype].append(meanRecv)
                filecontent = []
                headerstr = ','
                replica='cpu,free_mem,send,recv,'
                secondheader = 'parameters,'
                for t in filetypes:
                    headerstr += '{},,,,'.format(t)
                    secondheader += replica
                filecontent.append(headerstr + '\n')
                filecontent.append(secondheader + '\n')
                for key, d in overallStats.items():
                    nextline = '{},'.format(key)
                    for filetype, l in d.items():
                        nextline += '{},{},{},{},'.format(l[0],l[1],l[2],l[3])
                    filecontent.append(nextline + '\n')
                DstatProc.writeToFile(filecontent, os.path.join(fullPathSecDir, "overall_dstat_stats{}.csv".format(secDir)))



    def extractConfigurationAverages(self, warmup, cooldown):
        for secDir in os.listdir(self.basepath):
            fullPathSecDir = os.path.join(self.basepath, secDir)
            if os.path.isdir(fullPathSecDir) and not secDir.startswith("init"):
                stats = defaultdict(lambda: defaultdict(list))
                for paramDir in os.listdir(fullPathSecDir):
                    fullPathParamDir = os.path.join(fullPathSecDir, paramDir)
                    if os.path.isdir(fullPathParamDir):
                        cpus = defaultdict(list)
                        mems = defaultdict(list)
                        netsends = defaultdict(list)
                        netrecvs = defaultdict(list)
                        for runDir in os.listdir(fullPathParamDir):
                            fullPathRunDir = os.path.join(fullPathParamDir, runDir)
                            if os.path.isdir(fullPathRunDir):
                                for vmDir in os.listdir(fullPathRunDir):
                                    fullPathVmDir = os.path.join(fullPathRunDir, vmDir)
                                    if os.path.isdir(fullPathVmDir):
                                        print("found dir: {}".format(fullPathVmDir))
                                        self.extractEntries(os.path.join(fullPathVmDir, 'dstat.csv'))
                                        self.cutWarmupCooldown(warmup, cooldown)
                                        self.calcStatistics()
                                        cpus[vmDir].append(self.avg_cpu)
                                        mems[vmDir].append(self.avg_free_mem)
                                        netrecvs[vmDir].append(self.avg_netw_recv)
                                        netsends[vmDir].append(self.avg_netw_send)
                        for key, values in cpus.items():
                            stats[key][paramDir].append(mean(values))
                        for key, values in mems.items():
                            stats[key][paramDir].append(mean(values))
                        for key, values in netsends.items():
                            stats[key][paramDir].append(mean(values))
                        for key, values in netrecvs.items():
                            stats[key][paramDir].append(mean(values))
                for key, dictionary in stats.items():
                    filecontent = []
                    filecontent.append("parameters,cpu_avg,free_mem_avg,send_avg,recv_avg\n")
                    for param, values in dictionary.items():
                        filecontent.append("{},{},{},{},{}\n".format(param, 
                                                                     values[0], 
                                                                     DstatProc.toMbytes(values[1]), 
                                                                     DstatProc.toMbytes(values[2]), 
                                                                     DstatProc.toMbytes(values[3])))
                    DstatProc.writeToFile(filecontent, os.path.join(fullPathSecDir, "{}_dstat_stats.csv".format(key)))
    @staticmethod
    def toMbytes(val):
        return val/1000000

    def extractEntries(self, dstatFilePath):
        self.entries = []
        skiplines = 5
        skipped = 0
        with open(dstatFilePath) as f:
            for line in f:
                splitting = line.split(',')
                if len(splitting) is 15:
                    if skiplines > 0:
                        skiplines -= 1
                        continue
                    elif len(splitting[0]) > 0:
                        #print(splitting)
                        entry = DstatEntry(splitting)
                        if entry.net_send > 100000:
                            self.entries.append(entry)
                        else:
                            skipped += 1
                    else:
                        print("ERROR: line has 14 commas but first element is empty: {}".format(line))
        print("skipped {} lines because of net_send < 1Mbytes/sec".format(skipped))

    def calcStatistics(self):
        # avg cpu usage
        # avg free mem
        # avg netw send
        # avg netw recv
        if len(self.entries) is 0:
            print("ERROR: no entries!")
            self.avg_cpu = -1
            self.avg_free_mem = -1
            self.avg_netw_send = -1
            self.avg_netw_recv = -1
            return
        self.avg_cpu = mean([100.0 - entry.cpu_idl for entry in self.entries])
        self.avg_free_mem = mean([entry.mem_free for entry in self.entries])
        self.avg_netw_send = mean([entry.net_send for entry in self.entries])
        self.avg_netw_recv = mean([entry.net_recv for entry in self.entries])


    @staticmethod
    def writeToFile(elements, filename):
        with open(filename, 'w') as f:
            f.writelines([str(el) for el in elements])

    def cutWarmupCooldown(self, warmup, cooldown):
        self.entries = self.entries[warmup:len(self.entries)-cooldown]

class DstatEntry:
    def __init__(self, splitting):
        self.cpu_usr = float(splitting[0])
        self.cpu_sys = float(splitting[1])
        self.cpu_idl = float(splitting[2])
        self.cpu_wai = float(splitting[3])
        self.cpu_hiq = float(splitting[4])
        self.cpu_siq = float(splitting[5])
        self.load_1m = float(splitting[6])
        self.load_5m = float(splitting[7])
        self.load_15m = float(splitting[8])
        self.mem_used = float(splitting[9])
        self.mem_buff = float(splitting[10])
        self.mem_cach = float(splitting[11])
        self.mem_free = float(splitting[12])
        self.net_recv = float(splitting[13])
        self.net_send = float(splitting[14])

def main():
    #mergeLogsFor2Middlewares("./requests.log", "./requests_half.log", "./combined.log")
    #dstatproc = DstatProc('C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_03-12-2018_11-06-33/')      # full data
    #dstatproc  = DstatProc('C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_09-12-2018_20-57-05/')     # sec6 data
    dstatproc = DstatProc('C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_11-12-2018_18-17-52/')        # sec5 only

    dstatproc.extractConfigurationAverages(0,3)
    dstatproc.mergeConfigurationAverages()

if __name__ == "__main__":
    main()