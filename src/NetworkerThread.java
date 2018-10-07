package ch.ethz.asltest;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;
import java.util.concurrent.BlockingQueue;

import java.io.IOException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;

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
        try (
            ServerSocketChannel serverSocket = ServerSocketChannel.open();
        ) {
            Selector selector = Selector.open();

            serverSocket.socket().bind(new InetSocketAddress(this.ipAddress, this.port));
            while (true) {
                SocketChannel socketChannel = serverSocket.accept();        // blocks until connection establishes
                logger.info("connection accepted!");

                ByteBuffer bb = ByteBuffer.allocate(84);  
                int bytesRead = socketChannel.read(bb);
                String s = new String(bb.array());
                logger.info(String.format("read %d bytes: %s", bytesRead, s));

                

            }
        } catch (IOException e) {
            logger.error("Exception at NetworkerThread!", e);
        }
    }
}