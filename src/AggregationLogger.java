package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;


public class AggregationLogger {
    private static final Logger logger = LogManager.getLogger("AggregationLogger");; 
    private final long PERIOD;    
    private final int workerId;
    private long currentPeriodStart;        

    private double numRequests;
    private long queueLengthSum;                 // Size of queue before this request was added to it by networkerThread
    private long queueWaitingTimeSum;           // Time in ms waiting in queue
    private long timeServerProcessingSum;       // Time in ms for memcached servers to process request
    private long timeInMiddlewareSum;           // Time in 1/10 ms the request spent in middleware
    private int numMissesSum;  
    private int numGetRequests;
    private int numMultigetRequests;
    private int numSetRequests;
    private int numMultigetKeysSum;

    public AggregationLogger(int workerId, long initTime, int period) {
        this.resetValues();
        this.workerId = workerId;
        this.currentPeriodStart = initTime;
        this.PERIOD = period;
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
    }

    private void aggregateLogReset() {
        logger.debug(String.format("Worker %d aggregates log data.", workerId));
        if(numRequests > 0) {
            double queueLengthAvg = (double)queueLengthSum / numRequests;
            double queueWaitingTimeAvg = (double)queueWaitingTimeSum / numRequests;
            double timeServerProcessingAvg = (double)timeServerProcessingSum / numRequests;
            double timeInMiddlewareAvg = (double)timeInMiddlewareSum /  numRequests;
            double numMissesAvg = (double)numMissesSum / numRequests;
            double numMultigetKeysAvg = (double)numMultigetKeysSum / numRequests;
            // queueLength queueWaitingTime timeServerProcessing timeInMiddleware numMisses numMultigetKeys numGetRequests numMultigetRequests numSetRequests
            logger.info(String.format("%d %d %.5f %.5f %.5f %.5f %.5f %.5f %d %d %d", this.currentPeriodStart, 
                                                                                    this.workerId,
                                                                                    queueLengthAvg, 
                                                                                    queueWaitingTimeAvg, 
                                                                                    timeServerProcessingAvg, 
                                                                                    timeInMiddlewareAvg, 
                                                                                    numMissesAvg, 
                                                                                    numMultigetKeysAvg, 
                                                                                    numGetRequests, 
                                                                                    numMultigetRequests, 
                                                                                    numSetRequests));
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
                    break;
                case MULTIGET:
                    this.numMultigetRequests++;
                    this.numMultigetKeysSum += request.numKeys();
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
