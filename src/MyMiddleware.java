package ch.ethz.asltest;

import java.util.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ArrayBlockingQueue;



public class MyMiddleware {

    private static final Logger logger = LogManager.getLogger("MyMiddleware");

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
        this.blockingRequestQueue = new ArrayBlockingQueue<Request>(1024);
        this.workerThreads = new Thread[numThreadsPTP];
    }

    void run() {
        try{
            logger.info("Start of MyMiddleware");
            logger.info(ip);
            logger.info(port);
            logger.info(mcAddresses);
            logger.info(numThreadsPTP);
            logger.info(readSharded);

            logger.info("Starting NetworkerThread...");
            Thread networkerThread = new Thread(new NetworkerThread(this.ip, this.port, this.blockingRequestQueue));
            networkerThread.start();

            // TODO: start worker threads!
            networkerThread.join();

        } catch (Exception e) {
            logger.error("Exception in MyMiddleware", e);
        }
    }

}