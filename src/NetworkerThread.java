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

    private ByteBuffer buffer;
    private final String ipAddress;
    private final int port;
    private final BlockingQueue<Request> blockingRequestQueue;


    public NetworkerThread(String ip, int port, BlockingQueue queue) {
        this.ipAddress = ip;
        this.port = port;
        this.blockingRequestQueue = queue;
        this.buffer = ByteBuffer.allocateDirect(Request.HEADER_SIZE_MAX + Request.VALUE_SIZE_MAX);
        logger.info(String.format("Instantiating NetworkerThread %s:%d", ip, port));
    }

    @Override
    public void run() {
        logger.info(String.format("Starting NetworkerThread %s:%d", ipAddress, port));
        try (ServerSocketChannel serverSocket = ServerSocketChannel.open();) {
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
                        logger.info(String.format("Networker clears buffer position: %d limit: %d capacity: %d", buffer.position(), buffer.limit(), buffer.capacity() ));
                        this.buffer.clear();    // prepare network thread buffer for new data
                        logger.info(String.format("Networker cleared buffer position: %d limit: %d capacity: %d", buffer.position(), buffer.limit(), buffer.capacity() ));
                        if(request.finished) {
                            // request has been finished already, start a new one
                            // TODO: reuse old request?
                            logger.debug("Creating a new request object");

                            request = new Request(socketChannel);
                            key.attach(request);
                        } else {
                            logger.debug("Request is not finished yet...");
                            logger.info(String.format("Request.buffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));

                        }
                        // else: attached request is continued until it is complete

                        // TODO: add acceptedAt time to request
                        int newBytesCount = -1;
                        try{
                            logger.info(String.format("Networker reads into buffer position: %d limit: %d capacity: %d", buffer.position(), buffer.limit(), buffer.capacity() ));
                            newBytesCount = socketChannel.read(buffer); // read new data into netthread-buffer
                            logger.info(String.format("Networker has read into buffer position: %d limit: %d capacity: %d", buffer.position(), buffer.limit(), buffer.capacity() ));
                        } catch (Exception e) {
                            logger.debug(Request.byteBufferToString(buffer));
                            logger.debug(String.format("bytesRead: %d", newBytesCount));
                            logger.error("Exception occurred",e);
                        }
                        if (newBytesCount == -1) {
                            logger.info("DISCONNECT");
                            key.cancel();
                            socketChannel.close();
                            //break;
                        } 
                        else if (newBytesCount > 0) {
                            logger.debug(String.format("read %d new bytes from request", newBytesCount));
                            // transfer data from netthread-buffer into request buffer
                            buffer.flip();
                            logger.info(String.format("Networker flips buffer position: %d limit: %d capacity: %d", buffer.position(), buffer.limit(), buffer.capacity() ));
                            String receivedStr = Request.byteBufferToString(buffer);
                            logger.debug(String.format("Networker received string from client: %s", receivedStr));
                            logger.info(String.format("Networker puts buffer into request.buffer position: %d limit: %d capacity: %d", request.buffer.position(), request.buffer.limit(), request.buffer.capacity() ));
                            request.buffer.put(buffer);
                            ByteBuffer requestBufView = request.buffer.duplicate();
                            requestBufView.flip();
                            String transferredStr = Request.byteBufferToString(requestBufView);
                            logger.debug(String.format("transferred %s from netthreadbuf to request.buffer: %s", receivedStr, transferredStr));
                            if(request.isComplete()) {
                                logger.debug("Request complete, adding it to queue");
                                logger.debug(String.format("received request of type %s", request.getType()));
                                // TODO: add addedToQueue time to request
                                // TODO: add currentQueueSize to request
                                try {
                                    this.blockingRequestQueue.put(request); // blocking if queue is full
                                } 
                                catch (InterruptedException e) {
                                    logger.error("Got interrupted while waiting for new space in queue", e);
                                }
                            }
                        } else {
                            logger.debug("NetworkerThread received 0 new bytes on read");
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