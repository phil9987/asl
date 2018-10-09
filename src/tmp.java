private void handleGet(Request request) throws IOException, ReadException {
    int idx = this.roundRobin();
    SocketChannel storageChannel = storageConns[idx];

    request.enableReading();

    while (request.buf.hasRemaining()) {
        storageChannel.write(request.buf);
    }

    long beginServiceMeasure = System.currentTimeMillis();
    int numValues = 0;

    while (true) {
        int newBytesCount = storageChannel.read(retrievalResponse.buf);
        if (newBytesCount < 0) {
            logger.error("A storage node has closed the connection");
            throw new RuntimeException("A storage node has closed the connection");
        }

        retrievalResponse.continueScan();

        while (retrievalResponse.hasNext()) {
            numValues++;
            retrievalResponse.skipNext();
            retrievalResponse.continueScan();
        }

        if (retrievalResponse.isFinished()) {
            break;
        }
    }

    request.numMisses = request.getNumKeys() - numValues;
    request.serviceTime = System.currentTimeMillis() - beginServiceMeasure;
    request.responseTime = (System.nanoTime() - request.acceptedAt) / 100000;

    logger.trace(request.toLogMessage(workerId));

    retrievalResponse.buf.flip();

    while (retrievalResponse.buf.hasRemaining()) {
        request.chan.write(retrievalResponse.buf);
    }

    retrievalResponse.clearEverything();
}

  