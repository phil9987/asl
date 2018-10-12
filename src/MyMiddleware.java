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

            int numServers = this.mcAddresses.size();
            final int numWorkersPerServer;
            final int numServersPerWorker;
            if(numThreadsPTP > numServers) {
                numWorkersPerServer = numThreadsPTP / numServers;
                numServersPerWorker = -1;
            } else {
                numServersPerWorker = numServers / numThreadsPTP;
                numWorkersPerServer = -1;
            }
            int serverOffset = -1;
            logger.info(15%4);
            for (int i = 0; i < workerThreads.length; i++) {
                if(numWorkersPerServer >= 0) {
                    // we want to assign several workers to one server initially
                    if(i % numWorkersPerServer == 0) {
                        serverOffset = (serverOffset + 1) % numServers;
                    }
                } 
                else if(numServersPerWorker >= 0) {
                    // we want to assign a server only every several server indizes
                    if(serverOffset == -1) {
                        serverOffset = 0;
                    }
                    else {
                        serverOffset = (serverOffset + numServersPerWorker) % numServers;
                    }
                }
                logger.info(String.format("Starting worker thread %d with serverOffset=%d (numWorkersPerServer=%d, numServersPerWorker=%d)", i, serverOffset, numWorkersPerServer, numServersPerWorker));
                Thread worker = new Thread(new WorkerThread(i, this.blockingRequestQueue, this.mcAddresses, this.readSharded, serverOffset));
                worker.start();
                workerThreads[i] = worker;
            }
            networkerThread.join();

        } catch (Exception e) {
            logger.error("Exception in MyMiddleware", e);
        }
    }

}