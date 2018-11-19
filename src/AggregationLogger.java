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
    private Map<Long, MutableInt> histogramMap = new HashMap<Long, MutableInt>();      // response time in 100us -> count
    private final int numServers;           

    private long numRequests;                   // Total number of requests during this period
    private long queueLengthSum;                // Sum of queue length before request has been added to queue
    private long queueWaitingTimeSum;           // Sum of time in ms request was waiting in queue
    private long timeServerProcessingSum;       // Sum of time in ms memcached servers used to process request
    private long timeInMiddlewareSum;           // Sum of time in ns request spent in middleware
    private int numMissesSum;                   // Sum of misses on memcached servers
    private int numGetRequests;                 // Total number of get requests during this period
    private int numMultigetRequests;            // Total number of multiget requests during this period
    private int numSetRequests;                 // Total number of set requests during this period
    private int numMultigetKeysSum;             // Sum of multiget keys
    private int[] serverCounts;                 // A count for each memcached server, indicating how often it has been served a request

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
        logger.info(String.format("Worker %d instantiated aggregationlogger with a period of %d and a starting timestamp of %d", workerId, period, initTime));
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
        //logger.debug(String.format("Worker %d aggregates log data.", workerId));
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

    private boolean inPeriod (long timestamp) {
        return (timestamp - currentPeriodStart) <= this.PERIOD;
    }

    public void prepareForShutdown() {
        this.aggregateLogReset();
    }

    public void logRequest(Request request) {
        if(inPeriod(request.timestampReceived)) {
            //logger.debug(String.format("Request %d is in period, adding its values to AggregationLogger (currentPeriodStart=%d)", request.timestampReceived, this.currentPeriodStart));
            long responseTime = request.timeInMiddleware / 100000;   // response time in 1/10ms
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
            //logger.debug(String.format("%s %d %d %d %d %d", t, request.queueLengthBeforeEntering, request.queueWaitingTime, request.timeServerProcessing, request.timeInMiddleware, request.numMissesOnServer ));
        }
        else {
            //logger.debug(String.format("Request %d not in period, aggregating and resetting data before increasing currentPeriodStart (currentPeriodStart=%d)", request.timestampReceived, this.currentPeriodStart));
            if(numRequests > 0) {
                aggregateLogReset();
            } else {
                //logger.debug("No requests yet, setting currentPeriodStart s.t. current requests fits in");
            }
            do {
                this.currentPeriodStart += this.PERIOD;
            } while(!inPeriod(request.timestampReceived));
            //logger.debug(String.format("Updated currentPeriodStart to %d, logging pending request now", this.currentPeriodStart));
            logRequest(request);
        }
    } 

}
