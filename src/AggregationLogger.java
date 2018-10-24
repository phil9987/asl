package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

import java.util.Map;
import java.util.HashMap;


public class AggregationLogger {
    private static final Logger logger = LogManager.getLogger("AggregationLogger");
    private final long PERIOD;    
    private final int MAX_NUM_SERVERS  = 3;
    private final int workerId;
    private long currentPeriodStart;     
    private Map<Long, MutableInt> histogramMap = new HashMap<Long, MutableInt>();

    private long numRequests;
    private long queueLengthSum;                 // Size of queue before this request was added to it by networkerThread
    private long queueWaitingTimeSum;           // Time in ms waiting in queue
    private long timeServerProcessingSum;       // Time in ms for memcached servers to process request
    private long timeInMiddlewareSum;           // Time in 1/10 ms the request spent in middleware
    private int numMissesSum;  
    private int numGetRequests;
    private int numMultigetRequests;
    private int numSetRequests;
    private int numMultigetKeysSum;
    private int[] serverCounts;
    private final int numServers;

    private class MutableInt {
        int value = 1; // note that we start at 1 since we're counting
        public void increment () { ++value;}
        public int  get() { return value; }
    }

    public AggregationLogger(int workerId, long initTime, int period, int numServers) {
        this.workerId = workerId;
        this.currentPeriodStart = initTime;
        this.PERIOD = period;
        this.numServers = numServers;
        this.serverCounts = new int[MAX_NUM_SERVERS];
        this.resetValues();

        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                logger.info(String.format("Shutdownhook of aggregationLogger for worker%d executing...", workerId));
                logHistogram();
                logger.info(String.format("Histogram info logged for worker%d", workerId));
            }
        });
        logger.debug(String.format("Worker %d instantiated aggregationlogger with a period of %d and a starting timestamp of %d", workerId, period, initTime));
    }

    private void resetValues() {
        this.numRequests = 0;
        this.queueLengthSum = 0;                             // Size of queue before this request was added to it by networkerThread
        this.queueWaitingTimeSum = 0;                      // Time in ms waiting in queue
        this.timeServerProcessingSum = 0;                  // Time in ms for memcached servers to process request
        this.timeInMiddlewareSum = 0;                      // Time in 1/10 ms the request spent in middleware
        this.numMissesSum = 0;  
        this.numGetRequests = 0;
        this.numMultigetRequests = 0;
        this.numSetRequests = 0;
        this.numMultigetKeysSum = 0;
        for(int i = 0; i < numServers; i++) {
            serverCounts[i] = 0;
        }
    }
    
    private void logHistogram() {
        for (Map.Entry<Long, MutableInt> entry : histogramMap.entrySet()){
            logger.trace(String.format("HISTOGRAM_W%d %d %d", workerId, entry.getKey(), entry.getValue().get()));
        }
    }

    private void aggregateLogReset() {
        logger.debug(String.format("Worker %d aggregates log data.", workerId));
        if(numRequests > 0) {
            /*double queueLengthAvg = (double)queueLengthSum / numRequests;
            double queueWaitingTimeAvg = (double)queueWaitingTimeSum / numRequests;
            double timeServerProcessingAvg = (double)timeServerProcessingSum / numRequests;
            double timeInMiddlewareAvg = (double)timeInMiddlewareSum /  numRequests;
            double numMissesAvg = (double)numMissesSum / numRequests;
            double numMultigetKeysAvg = (double)numMultigetKeysSum / numRequests;
            // timestamp workerId queueLength queueWaitingTime timeServerProcessing timeInMiddleware numMisses numMultigetKeys numGetRequests numMultigetRequests numSetRequests
            logger.trace(String.format("%d %d %.5f %.5f %.5f %.5f %.5f %.5f %d %d %d", this.currentPeriodStart, 
                                                                                    this.workerId,
                                                                                    queueLengthAvg, 
                                                                                    queueWaitingTimeAvg, 
                                                                                    timeServerProcessingAvg, 
                                                                                    timeInMiddlewareAvg, 
                                                                                    numMissesAvg, 
                                                                                    numMultigetKeysAvg, 
                                                                                    numGetRequests, 
                                                                                    numMultigetRequests, 
                                                                                    numSetRequests));*/
            logger.trace(String.format("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", this.currentPeriodStart, 
                                                                                    this.workerId,
                                                                                    queueLengthSum, 
                                                                                    queueWaitingTimeSum, 
                                                                                    timeServerProcessingSum, 
                                                                                    timeInMiddlewareSum, 
                                                                                    numMissesSum, 
                                                                                    numMultigetKeysSum, 
                                                                                    numGetRequests, 
                                                                                    numMultigetRequests, 
                                                                                    numSetRequests,
                                                                                    numRequests,
                                                                                    serverCounts[0],
                                                                                    serverCounts[1],
                                                                                    serverCounts[2]));
            this.resetValues();
        }
        else {
            logger.error("No data to aggregate, numRequests == 0");
        }

    }

    private boolean inPeriod (long timestamp) {
        return (timestamp - currentPeriodStart) <= this.PERIOD;
    }

    public void logRequest(Request request) {
        if(inPeriod(request.timestampReceived)) {
            logger.debug(String.format("Request %d is in period, adding its values to AggregationLogger (currentPeriodStart=%d)", request.timestampReceived, this.currentPeriodStart));
            long responseTime = request.timeInMiddleware / 10000;   // response time in 100us
            MutableInt count = histogramMap.get(responseTime);
            if (count == null) {
                histogramMap.put(responseTime, new MutableInt());
            }
            else {
                count.increment();
            }
            this.numRequests++;
            this.queueLengthSum          += request.queueLengthBeforeEntering;
            this.queueWaitingTimeSum     += request.queueWaitingTime;
            this.timeServerProcessingSum += request.timeServerProcessing;
            this.timeInMiddlewareSum     += request.timeInMiddleware;
            this.numMissesSum            += request.numMissesOnServer; 
            String t = "";
            switch (request.getType()) {
                case SET:
                    this.numSetRequests++;
                    t = "SET";
                    break;
                case GET:
                    this.numGetRequests++;
                    t="GET";
                    break;
                case MULTIGET:
                    this.numMultigetRequests++;
                    this.numMultigetKeysSum += request.numKeys();
                    t="MGET";
                    break;
                default:
            }
            for(int i = 0; i < request.numServersUsed; i++) {
                int idx = (request.firstServerUsed + i) % numServers;
                serverCounts[idx] += 1;
            }
            logger.debug(String.format("%s %d %d %d %d %d", t, request.queueLengthBeforeEntering,
            request.queueWaitingTime, request.timeServerProcessing, request.timeInMiddleware, request.numMissesOnServer ));
        }
        else {
            logger.debug(String.format("Request %d not in period, aggregating and resetting data before increasing currentPeriodStart (currentPeriodStart=%d)", request.timestampReceived, this.currentPeriodStart));
            if(numRequests > 0) {
                aggregateLogReset();
            } else {
                logger.debug("No requests yet, setting currentPeriodStart s.t. current requests fits in");
            }
            do {
                this.currentPeriodStart += this.PERIOD;
            } while(!inPeriod(request.timestampReceived));
            logger.debug(String.format("Updated currentPeriodStart to %d, logging pending request now", this.currentPeriodStart));
            logRequest(request);

            

        }
    } 

}
