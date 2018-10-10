package ch.ethz.asltest;

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

    public Request(SocketChannel channel) {
        this.requestorChannel = channel;
        this.buffer = ByteBuffer.allocate(HEADER_SIZE_MAX + VALUE_SIZE_MAX);   // using non-direct bytebuffer here
    }

    public enum Type {
        GET,
        MULTIGET,
        SET,
        NOT_SET,
        INVALID;
    }


    public SocketChannel getRequestorChannel() {
        return this.requestorChannel;
    }

    public Type getType() {
        if(this.type == Type.NOT_SET) {
            byte firstChar = this.buffer.get(0);
            logger.debug(String.format("first character = %c", firstChar));
            switch(firstChar) {
                case 'g':   if(this.buffer.get(3) == 's') {
                                this.type = Type.MULTIGET;
                            } else {
                                this.type = Type.GET;
                            }
                case 's':   this.type = Type.SET;
                            break;
            }
        }
        return this.type;
    }

    public boolean isComplete() {
        if(this.buffer.position() > 0) {
            byte lastChar = this.buffer.get(this.buffer.position()-1);
            if(lastChar == '\n') {
                logger.debug("last character of buffer is newline, request is complete");
            }
            else {
                logger.debug(String.format("last character of buffer is not newline, request not finished yet: %c", lastChar));
            }
            return lastChar == '\n';
        }
        else {
            return false;
        }
    }

    boolean dataComplete() {
        // TODO: implement this
        return true;
    }

    boolean containsNewline() {
        // TODO: implement this
        return true;
    }

    public static boolean containsNewline(ByteBuffer buf) {
        // TODO: parse request and store offset
        return true;
    }

    public static String byteBufferToString(ByteBuffer buf) {
        final byte[] bytes = new byte[buf.remaining()];
     
        buf.duplicate().get(bytes);
     
        return new String(bytes);
    }

    public static ByteBuffer stringToByteBuffer(String str) {
        return StandardCharsets.US_ASCII.encode(str);
    }

}