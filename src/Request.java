package ch.ethz.asltest;

import java.util.*;

import java.nio.channels.SocketChannel;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;


import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;



public class Request {

    static final int HEADER_SIZE_MAX = 256;        // max key size according to memcached protocol = 250
    static final int VALUE_SIZE_MAX = 4096;     // According to instructions


    private static final Logger logger = LogManager.getLogger("Request");


    private static final byte G_BYTE  = 103;
    private static final byte S_BYTE  = 115;

    private Type type = Type.NOT_SET;
    private int size;
    private String body;
    private SocketChannel requestorChannel;
    ByteBuffer buffer;
    String requestStr;
    List<Integer> offsets;
    boolean finished = false;

    public Request(SocketChannel channel) {
        this.requestorChannel = channel;
        this.buffer = ByteBuffer.allocate(HEADER_SIZE_MAX + VALUE_SIZE_MAX);   // using non-direct bytebuffer here
    }

    public enum Type {
        GET,
        MULTIGET,
        SET,
        NOT_SET,
        UNKNOWN;
    }


    public SocketChannel getRequestorChannel() {
        return this.requestorChannel;
    }

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
                                this.type = Type.UNKNOWN;
                            }
                            break;
                case 's':   this.type = Type.SET;
                            break;
            }
        }
        return this.type;
    }

    public boolean isComplete() {
        return isComplete(this.buffer);
    }

    public static boolean isComplete(ByteBuffer buf) {
        boolean res = false;
        if(buf.position() > 0) {
            byte lastChar = buf.get(buf.position()-1);
            res = lastChar == '\n';
            if(res) {
                logger.debug("last character of buffer is newline, request is complete");
            }
            else {
                logger.debug(String.format("last character of buffer is not newline, request not finished yet: %c", lastChar));
            }
            return res;
        }
        else {
            if (buf.limit() < buf.capacity()) {
                ByteBuffer b = buf.duplicate();
                b.flip();
                logger.debug(String.format("buffer flipped for complete check: position: %d limit: %d capacity: %d", b.position(), b.limit(), b.capacity()));
                if(b.position() > 0) res = isComplete(b);
            }
        }
        return res;
    }

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
     * Returns the number of white spaces that are contained in the request
     */
    private int parseGet() {
        // requires this.isComplete() == true else might run infinitely
        offsets = new ArrayList<Integer>();
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

    public int numGets() {
        int res = 0;
        if (isComplete()) {
            switch (this.type) {
                case MULTIGET:
                case GET:           // get can also be multiget according to protocol rules
                    res = parseGet();
                    break;
                default:
                    break;
            }
        }
        else {
            res = -1;
        }
        return res;
    }

    public static String byteBufferToString(ByteBuffer buf) {
        final byte[] bytes = new byte[buf.remaining()];
     
        buf.duplicate().get(bytes);
     
        return new String(bytes);
    }

    public static ByteBuffer stringToByteBuffer(String str) {
        return StandardCharsets.US_ASCII.encode(str);
    }

    public static boolean getResponseIsComplete(ByteBuffer responseBuf) {
        ByteBuffer buf = responseBuf.duplicate();
        int current_pos = buf.position();
        if(current_pos >= 5) {
            byte fifth = buf.get(current_pos-5);
            byte fourth = buf.get(current_pos-4);
            byte third = buf.get(current_pos-3);
            byte snd = buf.get(current_pos-2);
            byte fst = buf.get(current_pos-1);
            boolean res =  (fifth == 'E' && 
                    fourth == 'N' && 
                    third == 'D' && 
                    snd == '\r' && 
                    fst == '\n'); 
            logger.debug(String.format("Response ends with following characters:%c%c%c%c%c complete: %b", fifth, fourth, third, snd, fst, res));

            return res;
        } else {
            return false;
        }
    }

}