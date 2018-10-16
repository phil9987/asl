package ch.ethz.asltest;

import java.util.*;

import java.nio.ByteBuffer;
import java.nio.channels.SocketChannel;
import java.nio.charset.StandardCharsets;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;



public class Request {

    static final int HEADER_SIZE_MAX = 256;        // max key size according to memcached protocol = 250
    static final int VALUE_SIZE_MAX = 4096;        // According to instructions
    private static final Logger logger = LogManager.getLogger("Request");

    private Type type = Type.NOT_SET;               // The type of this request
    private SocketChannel requestorChannel;         // The socketchannel to the memtier client
    ByteBuffer buffer;                              // The buffer which stores the memtier request
    String requestStr;                              // For get requests the buffer is converted into a string for convenience
    List<Integer> offsets;                          // A list of space-character-indizes. The last index is of '\r' character

    long timestampReceived = -1;                    // Timestamp when request became readable in middleware
    long timestampQueueEntered = -1;                // Timestamp when entering the queue
    int queueLengthBeforeEntering = -1;             // Size of queue before this request was added to it by networkerThread
    long queueWaitingTime = -1;                     // Time in ms waiting in queue
    long timeServerProcessing = -1;                 // Time in ms for memcached servers to process request
    long timeInMiddleware = -1;                     // Time in 1/10 ms the request spent in middleware
    int numMissesOnServer = -1;                     // Number of cache misses on memcached server (in response)

    /**
     * Constructor
     */
    public Request(SocketChannel channel) {
        this.requestorChannel = channel;
        this.buffer = ByteBuffer.allocateDirect(HEADER_SIZE_MAX + VALUE_SIZE_MAX);
        offsets = new ArrayList<Integer>();
    }

    /**
     * Encodes the type of the request
     */
    public enum Type {
        GET,
        MULTIGET,
        SET,
        NOT_SET,
        UNKNOWN;
    }

    /**
     * Accessor function for requestorChannel
     */
    public SocketChannel getRequestorChannel() {
        return this.requestorChannel;
    }

    /**
     * Reset current object such that it can be reused
     */
    public void reset(SocketChannel channel) {
        this.requestorChannel = channel;
        this.type = Type.NOT_SET;
        this.buffer.clear();
        this.offsets = new ArrayList<Integer>();
        this.requestStr = "";
        this.timestampReceived = -1;
        this.timestampQueueEntered = -1;
        this.queueWaitingTime = -1;
        this.timeServerProcessing = -1;
        this.timeInMiddleware = -1;
        this.queueLengthBeforeEntering = -1;
        this.numMissesOnServer = -1;
    }

    /**
     * Parses the type of the request stored in this.buffer.
     * Result is returned and stored in this.type
     */
    public Type getType() {
        if(this.type == Type.NOT_SET) {
            byte firstChar = this.buffer.get(0);
            logger.debug(String.format("first character = %c", firstChar));
            switch(firstChar) {
                case 'g':   if(this.isComplete()) {
                                int numSpaces = parseGet();
                                logger.debug(String.format("NumSpaces from parseGet(): %d", numSpaces));
                                if(numSpaces == 1) {
                                    this.type = Type.GET;
                                }
                                else {
                                    this.type = Type.MULTIGET;
                                }
                            }
                            else {
                                // request is not complete yet, we cannot determine type
                                logger.error(String.format("Error: getType call even though request is incomplete: %s", byteBufferToString(this.buffer)));
                                this.type = Type.UNKNOWN;
                            }
                            break;
                case 's':   this.type = Type.SET;
                            break;
            }
        }
        return this.type;
    }

    /**
     * isComplete for this object
     */
    public boolean isComplete() {
        return isComplete(this.buffer);
    }

    /**
     * Checks whether the request stored in buf is already complete.
     * Both read and write mode are supported, end is identified by '\n' character
     */
    public static boolean isComplete(ByteBuffer buf) {
        boolean res = false;
        logger.debug(String.format("Checking if buffer is completed: position: %d limit: %d capacity: %d", buf.position(), buf.limit(), buf.capacity()));
        byte lastChar = 'a';
        if(buf.position() > 0) {
            logger.debug("Checking lastchar behind buf.position()");
            lastChar = buf.get(buf.position()-1);
        }
        else {
            if(buf.limit() < buf.capacity()) {
                logger.debug("Checking lastchar behind buf.limit()");
                lastChar = buf.get(buf.limit()-1);
            }
        }
        res = lastChar == '\n';
        if(res) {
            logger.debug("last character of buffer is newline, request is complete");
        }
        else {
            logger.debug(String.format("last character of buffer is not newline, request not finished yet: %c", lastChar));
        }
        return res;
    }

    /**
     * Given the number of memcached servers it splits the multiget request into several (up to numServers) requests.
     * Returns only the keys per request which need to be added into a request in the following way: get <keys>\r\n
     */
    public ByteBuffer[] splitGetsKeys(int numServers) {
        // requires parseGet() to be executed beforehand. This function is executed by getType() in NetworkerThread
        logger.debug(String.format("Splitting multiget keys for %d servers", numServers));
        int numKeys = offsets.size() - 1;
        logger.debug(String.format("Number of keys: %d", numKeys));
        int keysPerRequest = numKeys / numServers;
        int overflow = numKeys % numServers;
        int numRequests = numServers;
        logger.debug(String.format("Number of keys per request: %d (overflow: %d, numRequests: %d)", keysPerRequest, overflow, numRequests));
        if(keysPerRequest == 0) {
            // if there are less keys than servers just put 1 key per request
            keysPerRequest = 1;     
            overflow = 0;
            numRequests = numKeys;
        }
        logger.debug(String.format("Number of keys per request: %d (overflow: %d, numRequests: %d)", keysPerRequest, overflow, numRequests));

        ByteBuffer[] res = new ByteBuffer[numRequests];
        if(numKeys > 0) {
            int offsetPointer = 0;
            ByteBuffer bufferPart;
            int offsetRange;
            for(int reqId = 0; reqId < numRequests; reqId++) {
                offsetRange = keysPerRequest;
                if(reqId == 0) {
                    offsetRange += overflow;
                }
                bufferPart = buffer.duplicate();
                int from = offsets.get(offsetPointer) + 1;
                int to = offsets.get(offsetPointer + offsetRange);
                bufferPart.position(from);
                bufferPart.limit(to);
                logger.debug(String.format("Keys for request %d: %s", reqId, byteBufferToString(bufferPart)));
                offsetPointer = offsetPointer + offsetRange;
                res[reqId] = bufferPart;
            }
        }
        else {
            logger.error("Called splitGets() when request.isComplete() == false");
            res[0] = this.buffer;
        }
        return res;
    } 

    /**
     * Converts buffer to String and parses it for space characers and endline. 
     * String is stored in this.requestStr and space positions are stored in this.offsets
     * The last element of this.offsets is the position of \r
     * Returns the number of white spaces that are contained in the request
     */
    private int parseGet() {
        // requires this.isComplete() == true else might run infinitely
        ByteBuffer buf = this.buffer.duplicate();
        buf.flip();
        this.requestStr = byteBufferToString(buf);
        logger.debug(String.format("Parsing get request: %s", requestStr));
        int spacePos = -1;
        do {
            spacePos = this.requestStr.indexOf(' ', spacePos+1);
            if(spacePos != -1) offsets.add(spacePos);
        } while(spacePos != -1);
        offsets.add(this.requestStr.indexOf('\r'));     // last offset is endline
        return offsets.size();
    }

    /**
     * Converts a bytebuffer into a string
     * Does not affect pointers of bytebuffer
     */
    public static String byteBufferToString(ByteBuffer buf) {
        final byte[] bytes = new byte[buf.remaining()];
     
        buf.duplicate().get(bytes);
     
        return new String(bytes);
    }

    /**
     * Converts a string into a bytebuffer
     */
    public static ByteBuffer stringToByteBuffer(String str) {
        return StandardCharsets.US_ASCII.encode(str);
    }

    /**
     * Checks if GET response sent by memcached server is complete.
     * Checks for "END\r\n" in the end of responseBuf
     */
    public static boolean getResponseIsComplete(ByteBuffer responseBuf) {
        ByteBuffer buf = responseBuf.duplicate();
        int current_pos = buf.position();
        boolean res = false;
        if(current_pos >= 5) {
            byte fifth = buf.get(current_pos-5);
            byte fourth = buf.get(current_pos-4);
            byte third = buf.get(current_pos-3);
            byte snd = buf.get(current_pos-2);
            byte fst = buf.get(current_pos-1);
            res =  (fifth == 'E' && 
                    fourth == 'N' && 
                    third == 'D' && 
                    snd == '\r' && 
                    fst == '\n'); 
        }
        return res;
    }

}