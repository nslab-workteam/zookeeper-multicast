package org.apache.zookeeper.server.quorum;

import java.io.IOException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import org.agrona.concurrent.BackoffIdleStrategy;
import org.agrona.concurrent.BusySpinIdleStrategy;
import org.agrona.concurrent.IdleStrategy;
import org.agrona.concurrent.NoOpIdleStrategy;
import org.agrona.concurrent.SigInt;

import org.apache.zookeeper.util.CircularBlockingQueue;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.aeron.Aeron;
import io.aeron.FragmentAssembler;
import io.aeron.Subscription;
import io.aeron.driver.MediaDriver;
import io.aeron.driver.ThreadingMode;
import io.aeron.logbuffer.FragmentHandler;

public class AeronMessageGetter extends Thread{
        private QuorumPeerConfig config;
    private final Logger LOG = LoggerFactory.getLogger(PacketSendAggregator.class);
    /**
     * Aeron used objects or property
     */
    private final String CHANNEL;
    private final int STREAM_ID = 101;
    private final int fragmentLimitCount = 10;
    private final MediaDriver.Context mdCtx;
    private final MediaDriver driver;
    private final Aeron.Context ctx;
    private final AtomicBoolean running;
    private final FragmentHandler fragmentHandler;
    private final FragmentHandler fragmentAssembler;

    /**
     * For Zookeeper
     */
    private final CircularBlockingQueue<byte[]> queue;

    public AeronMessageGetter() {
        config = new QuorumPeerConfig();
        queue = new CircularBlockingQueue<byte[]>(100);
        /**
         * Get config from zookeeper for address
         */
        CHANNEL = "aeron:udp?endpoint=225.0.0.3:40123|interface=" + config.getInterfaceAddr();
        mdCtx = new MediaDriver.Context()
                .termBufferSparseFile(false)
                .useWindowsHighResTimer(true)
                .threadingMode(ThreadingMode.DEDICATED)
                .conductorIdleStrategy(BusySpinIdleStrategy.INSTANCE)
                .receiverIdleStrategy(NoOpIdleStrategy.INSTANCE)
                .senderIdleStrategy(NoOpIdleStrategy.INSTANCE);

        running = new AtomicBoolean(true);
        // Register a SIGINT handler for graceful shutdown.
        SigInt.register(() -> running.set(false));

        // dataHandler method is called for every new datagram received
        fragmentHandler =
            (buffer, offset, length, header) ->
            {
                LOG.info("Read out {} bytes", length);
                final byte[] data = new byte[length];
                buffer.getBytes(offset, data);
                queue.offer(data);
            };
        fragmentAssembler = new FragmentAssembler(fragmentHandler);
        driver = MediaDriver.launchEmbedded(mdCtx);
        ctx = new Aeron.Context();
        ctx.aeronDirectoryName(driver.aeronDirectoryName());
    }

    @Override
    public void run() {
        /**
         * Start Aeron session
         */
        Aeron aeron = Aeron.connect(ctx);
        Subscription subscription = aeron.addSubscription(CHANNEL, STREAM_ID);
        IdleStrategy idleStrategy = new BackoffIdleStrategy(
                100, 10, TimeUnit.MICROSECONDS.toNanos(1), TimeUnit.MICROSECONDS.toNanos(100));
        
        while (running.get()) {
            // poll delivers messages to the dataHandler as they arrive
            // and returns number of fragments read, or 0
            // if no data is available.
            final int fragmentsRead = subscription.poll(fragmentHandler, fragmentLimitCount);
            // Give the IdleStrategy a chance to spin/yield/sleep to reduce CPU
            // use if no messages were received.
            idleStrategy.idle(fragmentsRead);
        }

        LOG.warn("Shutting down...");
        subscription.close();
        aeron.close();
    }

    public byte[] getBytes() throws Exception {
        return queue.poll(1, TimeUnit.MILLISECONDS);
    }
}
