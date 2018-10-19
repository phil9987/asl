package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;

import java.io.IOException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.ByteBuffer;

import java.net.InetSocketAddress;

import java.util.concurrent.BlockingQueue;
import java.util.Set;
import java.util.Iterator;
import java.util.List;


public class WorkerThread implements Runnable {

    private final static int SET_MAX_RESPONSE_SIZE = 24;
    private static final ByteBuffer SET_POSITIVE_RESPONSE_BUF = Request.stringToByteBuffer("STORED\r\n");
    private ByteBuffer serverSetResponseBuffer = ByteBuffer.allocateDirect(SET_MAX_RESPONSE_SIZE);
    private static final int MAX_NUM_GET_REQUESTS = 10;
    private ByteBuffer serverGetResponseBuffer = ByteBuffer.allocateDirect(10*(Request.HEADER_SIZE_MAX + Request.VALUE_SIZE_MAX));       // TODO: does this make sense? Shall we unify response buffers into one big buffer?

    private final ByteBuffer GET_REQ_BEGINING = Request.stringToByteBuffer("get ");
    private final ByteBuffer REQ_LINE_END = Request.stringToByteBuffer("\r\n");
    private ByteBuffer[] bufferPartsGetReq = new ByteBuffer[3];  // bytebuffer array to construct get requests from multiget

    private static final Logger logger = LogManager.getLogger("WorkerThread");
    static final int DEFAULT_MEMCACHED_PORT = 11211;
    private final int id;
    private final int numServers;
    private final int serverOffset;
    private int roundrobinvariable;
    private final BlockingQueue<Request> blockingRequestQueue;
    private final List<String> serverAdresses;
    private final SocketChannel[] serverConnections;
    private final boolean readSharded;
    private final AggregationLogger aggregationLogger;

    public WorkerThread(int id, BlockingQueue<Request> queue, List<String> serverAdresses, boolean readSharded, int serverOffset, long initialTimestamp) {
        this.id = id;
        this.blockingRequestQueue = queue;
        this.serverAdresses = serverAdresses;
        this.serverConnections = new SocketChannel[serverAdresses.size()];
        this.readSharded = readSharded;
        this.numServers = serverAdresses.size();
        this.serverOffset = serverOffset;
        this.roundrobinvariable = -1;
        this.REQ_LINE_END.rewind();
        this.GET_REQ_BEGINING.rewind();
        this.aggregationLogger = new AggregationLogger(this.id, initialTimestamp, 1000000000);  // aggregationLogger which logs every 1s
        logger.debug(String.format("Instantiating WorkerThread %d with serverOffset %d", this.id, this.serverOffset));
    }

    /**
     * Returns next server to query for get requests.
     * Increases roundrobinvariable by 1.
     */
    private int getServerIdx() {
        roundrobinvariable = (roundrobinvariable + 1) % numServers;
        int next_idx = (serverOffset + roundrobinvariable) % numServers;
        //logger.debug(String.format("Worker %d next server idx: %d roundrobinvariable: %d", this.id, next_idx, roundrobinvariable));
        return next_idx;
    }

    /**
     * Returns next server to query for multiget requests.
     * Increases roundrobinvariable by numRequests
     */
    private int getServerIdxForSeveralRequests(int numRequests) {
        int res = getServerIdx();
        roundrobinvariable += numRequests-1;
        return res;
    }

    /**
     * Sends a set request to all storage servers and forwards one of the memcached server responses 
     * to the requesting client.
     * In case one server responded with an error, the error message is sent to the requesting client.
     */
    private void processSet(Request request) throws IOException {
        //logger.debug(String.format("Worker %d sends set request to all memcached servers...", this.id));
        request.buffer.flip();
        long serverProcessingBegin = System.currentTimeMillis();

        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            SocketChannel serverChannel = serverConnections[serverIdx];
            logger.debug(String.format("Worker %d sends set request to memcached server %d...", this.id, serverIdx));
            request.buffer.rewind();
            while (request.buffer.hasRemaining()) {
                //logger.debug(String.format("sending request to server, %d remaining", request.buffer.remaining()));
                serverChannel.write(request.buffer);
            }
        }
        String errResponse = "";

        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            logger.debug(String.format("Worker %d reads response from memcached server %d", this.id, serverIdx));
            SocketChannel serverChannel = serverConnections[serverIdx];
            serverSetResponseBuffer.clear();
            serverChannel.read(serverSetResponseBuffer);
            serverSetResponseBuffer.flip();
            //response = Request.byteBufferToString(serverSetResponseBuffer);
            //logger.debug(String.format("Worker %d received response from memcached server %d: %s", this.id, serverIdx, response.trim()));
            if (!serverSetResponseBuffer.equals(WorkerThread.SET_POSITIVE_RESPONSE_BUF)) {
                logger.error(String.format("Memcached server %d returned error to worker %d", serverIdx, this.id));
                errResponse = Request.byteBufferToString(serverSetResponseBuffer);
            }
        }
        request.timeServerProcessing = System.currentTimeMillis() - serverProcessingBegin;
        request.timeInMiddleware = (System.nanoTime() - request.timestampReceived) / 100000;
        logger.debug(String.format("Worker %d sends response to requesting client.", this.id));
        SocketChannel requestorChannel = request.getRequestorChannel();
        if(errResponse.isEmpty()) {
            serverSetResponseBuffer.rewind();
            while (serverSetResponseBuffer.hasRemaining()) {
                //logger.debug(String.format("sending response to requestor, %d remaining", serverSetResponseBuffer.remaining()));
                requestorChannel.write(serverSetResponseBuffer);
            } 
        }
        else {
            // error occurred on at least one server, forwarding one of the error messages
            ByteBuffer errBuf = Request.stringToByteBuffer(errResponse);
            //logger.debug(String.format("errror bytebuffer position: %d limit: %d capacity: %d", errBuf.position(), errBuf.limit(), errBuf.capacity() ));
            while (errBuf.hasRemaining()) {
                //logger.debug(String.format("sending error response to requestor, %d remaining", errBuf.remaining()));
                requestorChannel.write(errBuf);
            }
        }
        // channels to memcached servers remain open intentionally, they get only closed on Middleware shutdown
    }

    /**
     * Sends a get request to one memcached server and forwards the response to the requesting client.
     * If multiple memcached servers exist one is selected using a round-robin scheme to ensure equal
     * payload.
     */
    private void processGet(Request request) throws IOException {
        int serverIdx = getServerIdx(); 
        logger.debug(String.format("Worker %d sends get request to memcached server %d.", this.id, serverIdx));
        request.buffer.flip();
        SocketChannel serverChannel = serverConnections[serverIdx];
        long serverProcessingBegin = System.currentTimeMillis();
        while (request.buffer.hasRemaining()) {
            //logger.debug(String.format("sending get request to server, %d remaining", request.buffer.remaining()));
            serverChannel.write(request.buffer);
        }

        logger.debug(String.format("Worker %d reads response from memcached server %d", this.id, serverIdx));
        serverGetResponseBuffer.clear();
        int bytesRead = 0;
        do {
            bytesRead = serverChannel.read(serverGetResponseBuffer);
        } while(!(Request.getResponseIsComplete(serverGetResponseBuffer) || bytesRead == 0 || bytesRead == -1)); // TODO: add better error handling
        request.timeServerProcessing = System.currentTimeMillis() - serverProcessingBegin;
        request.timeInMiddleware = (System.nanoTime() - request.timestampReceived) / 100000;
        int numValues = serverGetResponseBuffer.position()/Request.VALUE_SIZE_MAX;
        int numMisses = request.numKeys() - numValues;
        logger.debug(String.format("Received %d values: %d misses", numValues, numMisses));        serverGetResponseBuffer.flip();
        //logger.debug(String.format("Worker %d received response from memcached server %d: %s (Complete: %b)", this.id, serverIdx, Request.byteBufferToString(serverGetResponseBuffer).trim(), Request.getResponseIsComplete(serverGetResponseBuffer)));
        logger.debug(String.format("Worker %d sends response to requesting client", this.id));
        SocketChannel requestorChannel = request.getRequestorChannel();
        serverGetResponseBuffer.rewind();
        while (serverGetResponseBuffer.hasRemaining()) {
            //logger.debug(String.format("sending response to requestor, %d remaining", serverGetResponseBuffer.remaining()));
            requestorChannel.write(serverGetResponseBuffer);
        } 
    }

    /**
     * Non-sharded mode: processGet(request)
     * Sharded mode: splits the keys into equal parts and sends each part to one server.
     * Then it collects the responses, merges them into one response and forwards it to the 
     * requesting client.
     */
    private void processMultiget(Request request) throws IOException{
        if(this.readSharded) {
            request.buffer.flip();
            ByteBuffer[] keyParts = request.splitGetsKeys(this.numServers);
            int numRequests = keyParts.length;
            int initialServerIdx = getServerIdxForSeveralRequests(numRequests);
            int serverIdx = initialServerIdx;
            logger.debug(String.format("Worker %d sends multiget request to possibly several servers starting with %d.", this.id, initialServerIdx));
            bufferPartsGetReq[0] = this.GET_REQ_BEGINING.duplicate();
            bufferPartsGetReq[2] = this.REQ_LINE_END.duplicate();
            long serverProcessingBegin = System.currentTimeMillis();
            for(int reqId = 0; reqId < numRequests; reqId++) {
                SocketChannel serverChannel = serverConnections[serverIdx];
                bufferPartsGetReq[1] = keyParts[reqId];
                bufferPartsGetReq[0].rewind();
                bufferPartsGetReq[2].rewind();
                //String start = Request.byteBufferToString(bufferPartsGetReq[0]);
                //String keyPart = Request.byteBufferToString(bufferPartsGetReq[1]);
                //String endl = Request.byteBufferToString(bufferPartsGetReq[2]);
                //logger.debug(String.format("start len = %d keyPart len = %d endl len = %d", start.length(), keyPart.length(), endl.length()));
                //logger.debug(String.format("Worker %d sends multiget request to memcached server %d: %s%s%s", this.id, serverIdx, start, keyPart, endl));
                logger.debug(String.format("Worker %d sends multiget request to memcached server %d", this.id, serverIdx));
                serverChannel.write(bufferPartsGetReq); // blocking
                serverIdx = (serverIdx + 1) % numServers;
            }

            serverIdx = initialServerIdx;
            String response = "";
            serverGetResponseBuffer.clear();
            for(int reqId = 0; reqId < numRequests; reqId++) {
                SocketChannel serverChannel = serverConnections[serverIdx];
                
                logger.debug(String.format("Worker %d reads multiget response from memcached server %d", this.id, serverIdx));
                int bytesRead = 0;
                do{
                    bytesRead = serverChannel.read(serverGetResponseBuffer);
                } while(!(Request.getResponseIsComplete(serverGetResponseBuffer) || bytesRead == 0 || bytesRead == -1)); // TODO: add better error handling
                //ByteBuffer debugbuf = serverGetResponseBuffer.duplicate();
                //debugbuf.flip();
                //response = Request.byteBufferToString(debugbuf);
                //logger.debug(String.format("Worker %d received response from memcached server %d: %s (Complete: %b)", this.id, serverIdx, response.trim(), Request.getResponseIsComplete(serverGetResponseBuffer)));
                logger.debug(String.format("Worker %d received response from memcached server %d: Complete: %b", this.id, serverIdx, Request.getResponseIsComplete(serverGetResponseBuffer)));
                if(reqId < numRequests -1) {
                    // remove end line from all requests but last one
                    // TODO: what if end line does not arrive in one piece?
                    //logger.debug(String.format("Worker %d resets serverGetResponseByteBuffer position: %d limit: %d capacity: %d", this.id, serverGetResponseBuffer.position(), serverGetResponseBuffer.limit(), serverGetResponseBuffer.capacity() ));
                    serverGetResponseBuffer.position(serverGetResponseBuffer.position()-5);
                    //logger.debug(String.format("Worker %d resetted serverGetResponseByteBuffer position: %d limit: %d capacity: %d", this.id, serverGetResponseBuffer.position(), serverGetResponseBuffer.limit(), serverGetResponseBuffer.capacity() ));
                }
                serverIdx = (serverIdx + 1) % numServers;
            }
            request.timeServerProcessing = System.currentTimeMillis() - serverProcessingBegin;
            request.timeInMiddleware = (System.nanoTime() - request.timestampReceived) / 100000;
            int numValues = serverGetResponseBuffer.position()/Request.VALUE_SIZE_MAX;
            int numMisses = request.numKeys() - numValues;
            logger.debug(String.format("Received %d values: %d misses", numValues, numMisses));
            serverGetResponseBuffer.flip();
            //logger.debug(String.format("serverGetResponesBuffer after flip position: %d limit: %d capacity: %d", serverGetResponseBuffer.position(), serverGetResponseBuffer.limit(), serverGetResponseBuffer.capacity() ));

            //logger.debug(String.format("Worker %d sends aggreageted response from memcached servers to requestor (Complete: %b): %s", this.id, Request.getResponseIsComplete(serverGetResponseBuffer), Request.byteBufferToString(serverGetResponseBuffer)));
            SocketChannel requestorChannel = request.getRequestorChannel();
            while (serverGetResponseBuffer.hasRemaining()) {
                //logger.debug(String.format("sending response to requestor, %d remaining", serverGetResponseBuffer.remaining()));
                requestorChannel.write(serverGetResponseBuffer);
            } 
        }
        else {
            // Treat multi-get like normal get: forward complete request to one server
            processGet(request);
        }
    }

    /**
     * The function that is initially called on every WorkerThread
     */
    @Override
    public void run() {
        logger.debug(String.format("Starting WorkerThread %d with serverOffset %d", this.id, this.serverOffset));
        try{
            for(int serverIdx = 0; serverIdx < serverAdresses.size(); serverIdx++) {
                String serverAddress = serverAdresses.get(serverIdx);
                String[] serverAddressSplitted = serverAddress.split(":");
                String ip = serverAddressSplitted[0];
                int port = DEFAULT_MEMCACHED_PORT;
                if(serverAddressSplitted.length > 1) {
                    try {
                        port = Integer.parseUnsignedInt(serverAddressSplitted[1]);
                    } catch(NumberFormatException e) {
                        logger.error(String.format("Unable to parse port of memcached server (%s), using default port...", serverAddressSplitted[1]), e);
                        port = DEFAULT_MEMCACHED_PORT;
                    }
                }
                logger.info(String.format("Connecting to memcached server %s:%d", ip, port));
                serverConnections[serverIdx] = SocketChannel.open();
                serverConnections[serverIdx].connect(new InetSocketAddress(ip, port));
                serverConnections[serverIdx].configureBlocking(true);
            }
            while(true) {
                Request request = this.blockingRequestQueue.take();     // worker is possibly waiting here
                request.queueWaitingTime = System.currentTimeMillis() - request.timestampQueueEntered;
                Request.Type type = request.getType();
                logger.debug(String.format("Worker %d starts handling request of type %s", this.id, type));
                switch(type) {
                    case GET:   processGet(request);
                                break;
                    case MULTIGET:  processMultiget(request);
                                break;
                    case SET:   processSet(request);
                                break;
                    default:
                        logger.error(String.format("Received request with wrong type: %s", type));
                }
                aggregationLogger.logRequest(request);
            }
        } catch(InterruptedException e) {
            logger.error(String.format("Worker %d got interrupted", this.id), e);
        } catch(IOException e) {
            logger.error(String.format("Worker %d had an IOException", this.id), e);
        } catch(Exception e) {
            logger.error(String.format("Worker %d had an Exception", this.id), e);
        }
    }
    
}

