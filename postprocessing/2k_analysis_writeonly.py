import json
import os
from collections import defaultdict
from statistics import mean
import pandas as pd
from postprocessing_memtier import read2kStatsData
import numpy as np

def calcAndAddEffects(dataframe, cols, SSE):
    ymean = dataframe[cols[-2]]
    lastcol_data = []
    SSX_col = []        # qA qB, qC qAB qBC qAC qABC
    totalVar = SSE
    for col in cols[:-2]:
        values = dataframe[col].values
        res = np.sum(np.multiply(values, ymean))
        res = res / 8.0
        lastcol_data.append(res)
    # for the variance we don't want q0
    for val in lastcol_data[1:]:
        ssx = 24 * val * val
        SSX_col.append(ssx)
        totalVar += ssx
    SSX_col.append(SSE)
    varEffectCol = ['-']
    for var in SSX_col:
        effect = var * 100.0 / totalVar
        varEffectCol.append(effect)

    lastcol_data.append('-')
    lastcol_data.append('-')
    df = pd.DataFrame([lastcol_data], columns=columns)
    dataframe = dataframe.append(df)

    varEffectCol.append('-')
    df = pd.DataFrame([varEffectCol], columns=columns)
    return dataframe.append(df)

    
sseThroughput = 0.0
sseLatency = 0.0
columns = ['I', 'xA', 'xB', 'xC', 'xAB', 'xBC', 'xAC', 'xABC', 'Ymean', 'Ystddev']
dfThroughput = pd.DataFrame(columns= columns)
dfLatency = pd.DataFrame(columns=columns)

#xA: workerThreads {8, 32}
#xB: numServers {1, 3}
#xC: numMW {1, 2}
basefolder = 'C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_09-12-2018_20-57-05/logSection6a/'
#basefolder = 'C:/Users/philip/Programming/AdvancedSystemsLab/Programming/data/experiment_logs_09-12-2018_23-35-05/logSection6a'
folder = './memtierCli32workerThreads8_1server_1mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, -1, -1, -1, 1, 1, 1, -1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, -1, -1, -1, 1, 1, 1, -1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads8_1server_2mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, -1, -1, 1, 1, -1, -1, 1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, -1, -1, 1, 1, -1, -1, 1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads8_3server_1mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, -1, 1, -1, -1, -1, 1, 1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, -1, 1, -1, -1, -1, 1, 1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads8_3server_2mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, -1, 1, 1, -1, 1, -1, -1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, -1, 1, 1, -1, 1, -1, -1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads32_1server_1mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, 1, -1, -1, -1, 1, -1, 1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, 1, -1, -1, -1, 1, -1, 1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads32_1server_2mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, 1, -1, 1, -1, -1, 1, -1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, 1, -1, 1, -1, -1, 1, -1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads32_3server_1mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, 1, 1, -1, 1, -1, -1, -1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, 1, 1, -1, 1, -1, -1, -1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency


folder = './memtierCli32workerThreads32_3server_2mw/'
mwMeanThroughput, mwStddevThroughput, mwMeanLatency, mwStddevLatency, sqErrThroughput, sqErrLatency = read2kStatsData(os.path.join(basefolder, folder, 'merged_stats.data'))
df = pd.DataFrame([[1, 1, 1, 1, 1, 1, 1, 1, mwMeanThroughput, mwStddevThroughput]], columns=columns)
dfThroughput = dfThroughput.append(df)

df = pd.DataFrame([[1, 1, 1, 1, 1, 1, 1, 1, mwMeanLatency, mwStddevLatency]], columns=columns)
dfLatency = dfLatency.append(df)

sseThroughput += sqErrThroughput
sseLatency += sqErrLatency

# ----
print("sqErrThrouput={} sqErrLatency={}".format(sseThroughput, sseLatency))
dfThroughput = calcAndAddEffects(dfThroughput, columns, sseThroughput)
pd.options.display.float_format = '{:.3f}'.format

dfLatency = calcAndAddEffects(dfLatency, columns, sseLatency)

print(dfThroughput.to_latex())
print(dfLatency.to_latex())