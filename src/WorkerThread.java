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
                try {
                    port = Integer.parseUnsignedInt(serverAddressSplitted[1]);
                } catch(NumberFormatException e) {
                    logger.error(String.format("Unable to parse port of memcached server (%s), using default port...", serverAddressSplitted[1]), e);
                    port = DEFAULT_MEMCACHED_PORT;
                }
                logger.info(String.format("Connecting to memcached server %s:%d", ip, port));
                SocketChannel serverChannel = SocketChannel.open();
                serverChannel.connect(new InetSocketAddress(ip, port));
                serverChannel.configureBlocking(true);
                serverConnections[serverIdx] = serverChannel;
            }
        } catch(IOException e) {
            logger.error("IOException occurred during connection attempt to memcached servers", e);
        }
    }
    
}

