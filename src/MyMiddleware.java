package ch.ethz.asltest;

import java.util.*;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.io.File;
import java.io.IOException;




public class MyMiddleware {

    private static final Logger logger = LogManager.getLogger("MyMiddleware");

	private final String ip;
	private final int port;
	private final List<String> mcAddresses;
	private final int numThreadsPTP;
    private final boolean readSharded;
    private final Thread[] workerThreads;
    private Thread networkerThread;
    private final BlockingQueue<Request> blockingRequestQueue;

    public MyMiddleware(String ip, int port, List<String> mcAddresses, int numThreadsPTP, boolean readSharded) {
        this.ip = ip;
        this.port = port;
        this.mcAddresses = mcAddresses;
        this.numThreadsPTP = numThreadsPTP;
        this.readSharded = readSharded;
        this.blockingRequestQueue = new LinkedBlockingQueue<Request>();
        this.workerThreads = new Thread[numThreadsPTP];

        Runtime.getRuntime().addShutdownHook(new Thread() {
            @Override
            public void run() {
                logger.info("Shutdownhook executing...");

                for(Thread worker : workerThreads) {
                    worker.interrupt(); // call shutdownhook of each worker
                }
                networkerThread.interrupt();

                logger.info("MyMiddleware is waiting before shutting down LogManager, to ensure all threads can log everything");
                try{
                    Thread.sleep(500);
                } catch(InterruptedException e) {
                    logger.info("MyMiddleware got interrupted while waiting for workerThreads");
                }
                for(int i = 0; i < numThreadsPTP; i++) {
                    try{
                        workerThreads[i].join();
                    } catch(InterruptedException e) {
                        logger.info(String.format("Worker%d got interrupted and has logged everything"));
                    }
                }
                logger.info("MyMiddleware is shutting down LogManager");
                LogManager.shutdown();
                try {
                    File f = new File("./logs/done.info");
                    f.createNewFile();
                } catch (IOException e) {
                    logger.error("Could not create done.info indicator file", e);
                }
            }
        });
    }

    /**
     * The function that is called to start MyMiddleware
     */
    void run() {
        try{
            logger.info(String.format("Start of MyMiddleware. ip=%s port=%d memcached_addresses=%s number_workerThreads=%d sharded=%b", ip, port, mcAddresses.toString(), numThreadsPTP, readSharded));
            logger.info("Starting NetworkerThread...");
            networkerThread = new Thread(new NetworkerThread(this.ip, this.port, this.blockingRequestQueue));
            
            networkerThread.start();

            int numServers = this.mcAddresses.size();
            final int numWorkersPerServer;
            final int numServersPerWorker;
            long initialWorkerTimestamp = System.nanoTime();
            if(numThreadsPTP > numServers) {
                numWorkersPerServer = numThreadsPTP / numServers;
                numServersPerWorker = -1;
            } 
            else {
                numServersPerWorker = numServers / numThreadsPTP;
                numWorkersPerServer = -1;
            }
            int serverOffset = -1;
            for (int i = 0; i < workerThreads.length; i++) {
                if(numWorkersPerServer >= 0) {
                    // we want to assign several workers to one server initially
                    if(i % numWorkersPerServer == 0) {
                        serverOffset = (serverOffset + 1) % numServers;
                    }
                }
                else if(numServersPerWorker >= 0) {
                    // we want to assign a worker only every several server indizes
                    if(serverOffset == -1) {
                        serverOffset = 0;
                    }
                    else {
                        serverOffset = (serverOffset + numServersPerWorker) % numServers;
                    }
                }
                logger.info(String.format("Creating worker thread %d with serverOffset=%d (numWorkersPerServer=%d, numServersPerWorker=%d)", i, serverOffset, numWorkersPerServer, numServersPerWorker));
                workerThreads[i] = new Thread(new WorkerThread(i, this.blockingRequestQueue, this.mcAddresses, this.readSharded, serverOffset, initialWorkerTimestamp));
                workerThreads[i].start();
            }
            networkerThread.join();

        } catch (Exception e) {
            logger.error("Exception in MyMiddleware", e);
        }
    }

}