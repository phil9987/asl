package ch.ethz.asltest;

import java.util.*;
//import org.apache.logging.log4j.LogManager;
//import org.apache.logging.log4j.Logger;

public class MyMiddleware {

    //private static final Logger logger = LogManager.getLogger("MyMiddleware");

	private final String ip;
	private final int port;
	private final List<String> mcAddresses;
	private final int numThreadsPTP;
    private final boolean readSharded;
    private final Thread[] workerThreads;
    private final BlockingQueue<Request> blockingRequestQueue;

    public MyMiddleware(String ip, int port, List<String> mcAddresses, int numThreadsPTP, boolean readSharded) {
        this.ip = ip;
        this.port = port;
        this.mcAddresses = mcAddresses;
        this.numThreadsPTP = numThreadsPTP;
        this.readSharded = readSharded;

        this.workerThreads = new Thread[numThreadsPTP];

    }

    void run() {
        try{
            //logger.info("Start of MyMiddleware");


        } catch (Exception e) {
            //logger.error("Exception in MyMiddleware", e);
        }
    }

}