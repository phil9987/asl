package ch.ethz.asltest;

import java.nio.channels.SocketChannel;
import java.nio.ByteBuffer;

import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.LogManager;



public class Request {

    private static final Logger logger = LogManager.getLogger("Request");


    private static final byte G_BYTE  = 103;
    private static final byte S_BYTE  = 115;

    private Type type = Type.NOT_SET;
    private int size;
    private String body;
    private SocketChannel channel;
    byte[] buffer;

    public Request(byte[] buffer) {
        this.buffer = buffer;
    }

    public enum Type {
        GET,
        MULTIGET,
        SET,
        NOT_SET,
        INVALID;
    }


    public SocketChannel getChannel() {
        return this.channel;
    }

    public Type getType() {
        if(this.type == Type.NOT_SET) {
            byte firstChar = this.buffer[0];
            logger.debug(String.format("first character = %c", firstChar));
            switch(firstChar) {
                case 'g':   if(this.buffer[3] == 's') {
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

    public static boolean isComplete(ByteBuffer buf) {
        return true;
    }

    boolean dataComplete() {
        // TODO: implement this
        return true;
    }

    boolean containsNewline() {
        // TODO: implement this
        return true;
    }

    public Request(String body) {
        this.body = body;
        // todo: process type;
    }
}