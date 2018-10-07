package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;
import java.util.concurrent.BlockingQueue;

import java.io.IOException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.nio.ByteBuffer;

import java.net.InetSocketAddress;



public class NetworkerThread implements Runnable {

    private static final Logger logger = LogManager.getLogger("NetworkerThread");

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
            serverSocketChannel.configureBlocking(false);
            serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
            while (true) {
                int numReady = selector.select();
                if (numReady == 0) continue;

                Set<SelectionKey> selectedKeys = selector.selectedKeys();
                Iterator<SelectionKey> keyIterator = selectedKeys.iterator();

                while (keyIterator.hasNext()) {
                    SelectionKey key = keyIterator.next();
                    if (key.isAcceptable()) {
                        logger.info("ACCEPT");
                        SocketChannel socketChannel = ((ServerSocketChannel) key.channel()).accept();
                        socketChannel.configureBlocking(false);
                        socketChannel.register(selector, SelectionKey.OP_READ, new Request(socketChannel));
                    } else if (key.isReadable()) {
                        logger.info("READ") ;
                        SocketChannel socketChannel = (SocketChannel) key.channel();
                        Request request = (Request) key.attachment();

                        // TODO: add acceptedAt time to request
                        if(request.isComplete()) {
                            logger.debug("Request complete, adding it to queue");
                            // TODO: add addedToQueue time to request
                            // TODO: add queueSize to request
                            this.blockingRequestQueue.add(request);
                        }
                    }
                }
            
            }
        } catch (IOException e) {
            logger.error("Exception at NetworkerThread!", e);
        }
    }
}