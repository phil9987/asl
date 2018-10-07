package ch.ethz.asltest;

import java.nio.channels.SocketChannel;


public class Request {

    private Type type;
    private String body;
    private SocketChannel channel;

    public Request(SocketChannel channel) {
        this.channel = channel;
    }

    public enum Type {
        GET,
        MULTIGET,
        SET,
        OTHER;
    }

    public SocketChannel getChannel() {
        return this.channel;
    }

    public Type getType() {
        return this.type;
    }

    public boolean isComplete() {
        if (this.getType() == Type.SET) {
            return this.containsNewline() && this.dataComplete();
        } else {
            return this.containsNewline();
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

    public Request(String body) {
        this.body = body;
        // todo: process type;
    }
}