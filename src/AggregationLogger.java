package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;


public class AggregationLogger {
    private final long PERIOD;    
    private static final Logger logger = LogManager.getLogger("AggregationLogger");; 
    private final int workerId;
    private long currentPeriodStart;               
    // private long timestampQueueEntered = -1;                 // Timestamp when entering the queue
    private int numRequests;
    private int queueLengthSum;                             // Size of queue before this request was added to it by networkerThread
    private long queueWaitingTimeSum;                      // Time in ms waiting in queue
    private long timeServerProcessingSum;                  // Time in ms for memcached servers to process request
    private long timeInMiddlewareSum;                      // Time in 1/10 ms the request spent in middleware
    private int numMissesSum;  
    private int numGetRequests;
    private int numMultigetRequests;
    private int numSetRequests;
    private int numKeysSum;

    public AggregationLogger(int workerId, long initTime, long period) {
        this.resetValues();
        this.workerId = workerId;
        this.currentPeriodStart = initTime;
        this.PERIOD = period;
    }

    private void resetValues() {
        this.numRequests = 0;
        this.queueLengthSum = 0;                             // Size of queue before this request was added to it by networkerThread
        this.queueWaitingTimeSum = 0;                      // Time in ms waiting in queue
        this.timeServerProcessingSum = 0;                  // Time in ms for memcached servers to process request
        this.timeInMiddlewareSum = 0;                      // Time in 1/10 ms the request spent in middleware
        this.numMissesSum = 0;  
        this.numGetRequests = 0;
        this.numSetRequests = 0;
        this.numKeysSum = 0;
    }

    private void aggregateLogReset() {
        logger.debug(String.format("Worker %d aggregates log data.", workerId));
        // TODO: calculate averages
        // TODO: log aggregates
        this.resetValues();
    }

    private boolean inPeriod (long timestamp) {
        return (timestamp - currentPeriodStart) <= this.PERIOD;
    }

    public void logRequest(Request request) {
        if(inPeriod(request.timestampReceived)) {
            logger.debug(String.format("Request %d is in period, adding its values to AggregationLogger"));
            this.numRequests++;
            this.queueLengthSum          += request.queueLengthBeforeEntering;
            this.queueWaitingTimeSum     += request.queueWaitingTime;
            this.timeServerProcessingSum += request.timeServerProcessing;
            this.timeInMiddlewareSum     += request.timeInMiddleware;
            this.numMissesSum            += request.numMissesOnServer; 
            switch (request.getType()) {
                case SET:
                    this.numSetRequests++;
                    break;
                case GET:
                    this.numGetRequests++;
                    this.numKeysSum++;
                    break;
                case MULTIGET:
                    this.numMultigetRequests++;
                    this.numKeysSum += request.numKeys();
                    break;
                default:
            }
        }
        else {
            aggregateLogReset();
            this.currentPeriodStart += this.PERIOD;
            logRequest(request);
        }
    } 

}
