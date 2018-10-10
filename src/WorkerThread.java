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

    /**
     * Sends the set request to all storage servers and sends a response back to the client
     */
    private void processSet(Request request) throws IOException {
        logger.info(String.format("Worker %d sends set request to all memcached servers...", this.id));
        logger.info(String.format("bytebuffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
        request.buffer.flip();
        logger.info(String.format("bytebuffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            SocketChannel serverChannel = serverConnections[serverIdx];
            logger.info(String.format("Worker %d sends set request to memcached server %d...", this.id, serverIdx));
            if(!serverChannel.isConnected() || !serverChannel.isOpen())
                logger.info("ERROR: no connection to memcached");
            request.buffer.rewind();
            logger.info(String.format("after rewind bytebuffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
            while (request.buffer.hasRemaining()) {
                logger.info(String.format("sending request to server, %d remaining", request.buffer.remaining()));
                serverChannel.write(request.buffer);
            }
            logger.info(String.format("bytebuffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
        }
        String response = "";
        String errResponse = "";
        logger.info(String.format("response bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));

        for (int serverIdx = 0; serverIdx < serverConnections.length; serverIdx++) {
            logger.info(String.format("Worker %d reads response from memcached server %d", this.id, serverIdx));
            SocketChannel serverChannel = serverConnections[serverIdx];
            serverSetResponseBuffer.clear();
            logger.info(String.format("after clear response bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
            serverChannel.read(serverSetResponseBuffer);
            logger.info(String.format("after read response bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
            // TODO: for debug purposes only, make more efficient
            serverSetResponseBuffer.flip();
            logger.info(String.format("after flip response bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
            response = Request.byteBufferToString(serverSetResponseBuffer);
            if(true) {
            //if (!serverSetResponseBuffer.equals(this.SET_POSITIVE_RESPONSE_BUF)) {
                logger.error(String.format("Memcached server %d returned error to worker %d", serverIdx, this.id));
                errResponse = response;
            }
            logger.info(String.format("after toString response bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
            logger.debug(String.format("Worker %d received response from memcached server %d: %s", this.id, serverIdx, response));
        }
        if(errResponse != "") {
            // at least one server responded an error
            response = errResponse;
            serverResponseBuffer = Request.stringToByteBuffer(response);
        }
        logger.info(String.format("Worker %d sends response to requesting client: %s", this.id, response));
        SocketChannel requestorChannel = request.getRequestorChannel();
        // TODO: log request
        logger.info(String.format("bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
        serverSetResponseBuffer.rewind();

        logger.info(String.format("bytebuffer position: %d limit: %d capacity: %d", serverSetResponseBuffer.position(), serverSetResponseBuffer.limit(), serverSetResponseBuffer.capacity() ));
        while (serverSetResponseBuffer.hasRemaining()) {
            logger.info(String.format("sending response to requestor, %d remaining", serverSetResponseBuffer.remaining()));
            requestorChannel.write(serverSetResponseBuffer);
        }
        // channel remains open intentionally

    }

    private void processGet(Request request) {
        int serverIdx = 0;  // TODO: add roundrobin scheme to select always a different one!
        // TODO

    }

    private void processMultiget(Request request) {
        // TODO
    }
    
}

