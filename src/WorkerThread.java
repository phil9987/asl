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
    ByteBuffer serverSetResponseBuffer = ByteBuffer.allocateDirect(SET_MAX_RESPONSE_SIZE);
    ByteBuffer serverGetResponseBuffer = ByteBuffer.allocateDirect(Request.HEADER_SIZE_MAX + Request.VALUE_SIZE_MAX);       // TODO: does this make sense? Shall we unify response buffers into one big buffer?

    private static final Logger logger = LogManager.getLogger("WorkerThread");
    static final int DEFAULT_MEMCACHED_PORT = 11211;
    private final int id;
    private final BlockingQueue<Request> blockingRequestQueue;
    private final List<String> serverAdresses;
    private final SocketChannel[] serverConnections;
    private final boolean readSharded;


    public WorkerThread(int id, BlockingQueue<Request> queue, List<String> serverAdresses, boolean readSharded) {
        this.id = id;
        this.blockingRequestQueue = queue;
        this.serverAdresses = serverAdresses;
        this.serverConnections = new SocketChannel[serverAdresses.size()];
        this.readSharded = readSharded;
    }

    /**
     * Sends the set request to all storage servers and sends a response back to the client
     */
    private void processSet(Request request) throws IOException {
        logger.debug(String.format("Worker %d sends set request to all memcached servers...", this.id));
        request.buffer.flip();
        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            SocketChannel serverChannel = serverConnections[serverIdx];
            logger.debug(String.format("Worker %d sends set request to memcached server %d...", this.id, serverIdx));
            request.buffer.rewind();
            while (request.buffer.hasRemaining()) {
                logger.debug(String.format("sending request to server, %d remaining", request.buffer.remaining()));
                serverChannel.write(request.buffer);
            }
        }
        String response = "";
        String errResponse = "";

        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            logger.debug(String.format("Worker %d reads response from memcached server %d", this.id, serverIdx));
            SocketChannel serverChannel = serverConnections[serverIdx];
            serverSetResponseBuffer.clear();
            serverChannel.read(serverSetResponseBuffer);
            // TODO: for debug purposes only, make more efficient
            serverSetResponseBuffer.flip();
            response = Request.byteBufferToString(serverSetResponseBuffer);
            logger.debug(String.format("Worker %d received response from memcached server %d: %s", this.id, serverIdx, response.trim()));
            if (!serverSetResponseBuffer.equals(this.SET_POSITIVE_RESPONSE_BUF)) {
                logger.error(String.format("Memcached server %d returned error to worker %d", serverIdx, this.id));
                errResponse = response;
            }
        }
        if(!errResponse.isEmpty()) {
            // at least one server responded an error
            response = errResponse;
        }
        logger.info(String.format("Worker %d sends response to requesting client: %s", this.id, response.trim()));
        SocketChannel requestorChannel = request.getRequestorChannel();
        // TODO: log request object
        if(errResponse.isEmpty()) {
            serverSetResponseBuffer.rewind();
            while (serverSetResponseBuffer.hasRemaining()) {
                logger.info(String.format("sending response to requestor, %d remaining", serverSetResponseBuffer.remaining()));
                requestorChannel.write(serverSetResponseBuffer);
            } 
        } else {
            // error occurred on at least one server, forwarding one of the error messages
            ByteBuffer errBuf = Request.stringToByteBuffer(errResponse);
            logger.info(String.format("errror bytebuffer position: %d limit: %d capacity: %d", errBuf.position(), errBuf.limit(), errBuf.capacity() ));
            while (errBuf.hasRemaining()) {
                logger.info(String.format("sending error response to requestor, %d remaining", errBuf.remaining()));
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
        int serverIdx = 0;  // TODO: add roundrobin scheme to select always a different one!
        logger.debug(String.format("Worker %d sends get request to memcached server %d.", this.id, serverIdx));
        request.buffer.flip();
        SocketChannel serverChannel = serverConnections[serverIdx];
        while (request.buffer.hasRemaining()) {
            logger.debug(String.format("sending get request to server, %d remaining", request.buffer.remaining()));
            serverChannel.write(request.buffer);
        }

        String response = "";
        logger.debug(String.format("Worker %d reads response from memcached server %d", this.id, serverIdx));
        serverGetResponseBuffer.clear();
        serverChannel.read(serverGetResponseBuffer);
        serverGetResponseBuffer.flip();
        response = Request.byteBufferToString(serverGetResponseBuffer);
        logger.debug(String.format("Worker %d received response from memcached server %d: %s", this.id, serverIdx, response.trim()));
        logger.info(String.format("Worker %d sends response to requesting client: %s", this.id, response.trim()));
        SocketChannel requestorChannel = request.getRequestorChannel();
        serverGetResponseBuffer.rewind();
        while (serverGetResponseBuffer.hasRemaining()) {
            logger.info(String.format("sending response to requestor, %d remaining", serverGetResponseBuffer.remaining()));
            requestorChannel.write(serverGetResponseBuffer);
        } 
    }

    private void processMultiget(Request request) {
        // TODO
    }

    @Override
    public void run() {
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
                /*SocketChannel serverChannel = SocketChannel.open();
                serverChannel.connect(new InetSocketAddress(ip, port));
                serverChannel.configureBlocking(true);
                serverConnections[serverIdx] = serverChannel;*/
                serverConnections[serverIdx] = SocketChannel.open();
                serverConnections[serverIdx].connect(new InetSocketAddress(ip, port));
                serverConnections[serverIdx].configureBlocking(true);
            }
            while(true) {
                Request request = this.blockingRequestQueue.take();     // worker is possibly waiting here
                Request.Type type = request.getType();
                logger.info(String.format("Worker %d starts handling request of type %s", this.id, type));
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

