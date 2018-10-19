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

public class NetworkerThread implements Runnable {

    private static final Logger logger = LogManager.getLogger("NetworkerThread");

    private final String ipAddress;
    private final int port;
    private final BlockingQueue<Request> blockingRequestQueue;


    public NetworkerThread(String ip, int port, BlockingQueue<Request> queue) {
        this.ipAddress = ip;
        this.port = port;
        this.blockingRequestQueue = queue;
        logger.info(String.format("Instantiating NetworkerThread %s:%d", ip, port));
    }

    /**
     * The function that is initially called for the NetworkerThread
     */
    @Override
    public void run() {
        logger.info(String.format("Starting NetworkerThread %s:%d", ipAddress, port));
        try (
            ServerSocketChannel serverSocket = ServerSocketChannel.open();  // this ensures that the sockets are closed on interrupt
            ) {
            Selector selector = Selector.open();
            serverSocket.socket().bind(new InetSocketAddress(this.ipAddress, this.port));
            serverSocket.configureBlocking(false);
            serverSocket.register(selector, SelectionKey.OP_ACCEPT);

            while (true) {
                int numReady = selector.select();       // number of channels that are ready
                if (numReady == 0) {
                    continue;
                }
                Set<SelectionKey> selectedKeys = selector.selectedKeys();   // keys of ready channels
                Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

                while (keyIterator.hasNext()) {
                    SelectionKey key = keyIterator.next();

                    if (!key.isValid()) {
                        continue;
                    }
                    
                    if (key.isAcceptable()) {
                        logger.info("ACCEPT");
                        SocketChannel socketChannel = ((ServerSocketChannel) key.channel()).accept();   // it's a serversocketchannel because it's an incoming connection
                        socketChannel.configureBlocking(false);
                        socketChannel.register(selector, SelectionKey.OP_READ, new Request(socketChannel));
                    }
                    else if (key.isReadable()) {
                        logger.info("READ") ;
                        SocketChannel socketChannel = (SocketChannel) key.channel();
                        Request request = (Request) key.attachment();
                        if(request.isComplete()) {
                            // request has been finished already, start a new one
                            logger.debug("Resetting request object");
                            request.reset(socketChannel);
                            //logger.info(String.format("Request.buffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
                            //key.attach(request);
                        } else {
                            // attached request is continued until it is complete
                            logger.debug("Request is not finished yet...");
                            //logger.info(String.format("Request.buffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
                        }

                        // TODO: add acceptedAt time to request
                        request.timestampReceived = System.nanoTime();
                        int newBytesCount = -1;
                        try{
                            newBytesCount = socketChannel.read(request.buffer); // read new data into netthread-buffer
                        } catch (Exception e) {
                            logger.error(String.format("Exception occurred: %s bytesRead: %d", Request.byteBufferToString(request.buffer), newBytesCount),e);
                        }
                        if (newBytesCount == -1) {
                            logger.info("DISCONNECT");
                            key.cancel();
                            socketChannel.close();
                            //break;
                        } 
                        else if (newBytesCount > 0) {
                            logger.debug(String.format("read %d new bytes from request", newBytesCount));
                            ByteBuffer requestBufView = request.buffer.duplicate();
                            requestBufView.flip();
                            //logger.debug(String.format("Received msg from client: %s", Request.byteBufferToString(requestBufView)));
                            if(request.isComplete()) {
                                logger.debug("Request of is complete, adding it to queue");
                                //logger.debug(String.format("received request of type %s", request.getType()));
                                request.timestampQueueEntered = System.nanoTime();
                                request.queueLengthBeforeEntering = blockingRequestQueue.size();
                                try {
                                    this.blockingRequestQueue.put(request); // blocking if queue is full
                                } 
                                catch (InterruptedException e) {
                                    logger.error("Got interrupted while waiting for new space in queue", e);
                                }
                            }
                        } else {
                            logger.error("NetworkerThread received 0 new bytes on read");
                        }
                    }
                    logger.debug("Networker removes processed key from iterator");
                    keyIterator.remove();       // Remove key from set so we don't process it twice
                }
            
            }
        } 
        catch (IOException e) {
            logger.error("Exception at NetworkerThread!", e);
        }
    }
}