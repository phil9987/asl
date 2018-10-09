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
    static final int KEY_SIZE_MAX = 250;    // max key size according to memcached protocol
    static final int VALUE_SIZE_MAX = 4096;     // According to instructions

    private final String ipAddress;
    private final int port;
    private final BlockingQueue<Request> blockingRequestQueue;


    public NetworkerThread(String ip, int port, BlockingQueue queue) {
        this.ipAddress = ip;
        this.port = port;
        this.blockingRequestQueue = queue;
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
            ByteBuffer buffer = ByteBuffer.allocateDirect(KEY_SIZE_MAX + VALUE_SIZE_MAX);


            while (true) {
                int numReady = selector.select();       // number of channels that are ready
                if (numReady == 0) continue;

                Set<SelectionKey> selectedKeys = selector.selectedKeys();   // keys of ready channels
                Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

                while (keyIterator.hasNext()) {
                    SelectionKey key = keyIterator.next();
                    keyIterator.remove();       // Remove key from set so we don't process it twice

                    if (!key.isValid()) {
                        continue;
                    }
                    
                    if (key.isAcceptable()) {
                        logger.info("ACCEPT");
                        SocketChannel socketChannel = ((ServerSocketChannel) key.channel()).accept();   // it's a serversocketchannel because it's an incoming connection
                        socketChannel.configureBlocking(false);
                        socketChannel.register(selector, SelectionKey.OP_READ);
                    } else if (key.isReadable()) {
                        logger.info("READ") ;
                        SocketChannel socketChannel = (SocketChannel) key.channel();

                        // TODO: add acceptedAt time to request
                        int newBytesCount = socketChannel.read(buffer);
                        // TODO: check if newBytesCount == -1 -> channel closed by client
                        logger.debug(String.format("read %d new bytes from request", newBytesCount));
                        
                        if(Request.isComplete(buffer)) {
                            logger.debug("Request complete, adding it to queue");
                            buffer.flip();
                            byte[] buf = new byte[buffer.remaining()];
                            buffer.get(buf);
                            Request newRequest = new Request(buf);
                            buffer.clear();
                            logger.debug(String.format("received request of type %s", newRequest.getType()));
                            // TODO: add addedToQueue time to request
                            // TODO: add currentQueueSize to request
                            try {
                                this.blockingRequestQueue.put(newRequest); // blocking if queue is full
                             } catch (InterruptedException e) {
                                logger.error("Got interrupted while waiting for new space in queue", e);
                            }
                        }
                    }
                }
            
            }
        } catch (IOException e) {
            logger.error("Exception at NetworkerThread!", e);
        }
    }
}