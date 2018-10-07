package asl;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;
import java.util.concurrent.BlockingQueue;

import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;


public class NetworkerThread implements Runnable {

    private static final Logger logger = LogManager.getLogger("NetworkerThread");

    private final String ipAddress;
    private final int port;
    private final BlockingQueue<Request> blockingRequestQueue;


    public NetworkerThread(String ip, int port, BlockingQueue queue) {
        this.ipAddress = ip;
        this.port = port;
        this.blockingRequestQueue = queue;
    }

    @Override
    public void run() {
        try (
            ServerSocketChannel socket = ServerSocketChannel.open();
        ) {
            Selector selector = Selector.open();

            serverSocketChannel.socket().bind(new InetSocketAddress(this.hostAddress, this.port));
            serverSocketChannel.configureBlocking(false);
            serverSocketChannel.register(selector, SelectionKey.OP_ACCEPT);
        }
    }
}