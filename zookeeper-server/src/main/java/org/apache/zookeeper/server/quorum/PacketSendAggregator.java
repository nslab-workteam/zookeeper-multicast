package org.apache.zookeeper.server.quorum;

import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.util.HashSet;

import io.aeron.Aeron;
import io.aeron.Publication;
import io.aeron.driver.MediaDriver;
import io.aeron.driver.ThreadingMode;
import org.agrona.concurrent.BusySpinIdleStrategy;
import org.agrona.concurrent.NoOpIdleStrategy;
import org.agrona.concurrent.SigInt;
import org.agrona.concurrent.UnsafeBuffer;
import org.agrona.BufferUtil;

import org.apache.jute.BinaryOutputArchive;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PacketSendAggregator {
    private HashSet<Long> zxidSet;
    private QuorumPeerConfig config;
    private final Logger LOG = LoggerFactory.getLogger(PacketSendAggregator.class);
    /**
     * Aeron used objects or property
     */
    private final String CHANNEL;
    private final int STREAM_ID = 101;
    private final MediaDriver.Context mdCtx;
    private final MediaDriver driver;
    private final Aeron.Context ctx;
    private final Aeron aeron;
    private final Publication publication;
    private final UnsafeBuffer buffer;

    /**
     * For zookeeper write data
     */
    private BinaryOutputArchive oa;

    public PacketSendAggregator() {
        /**
         * For non-repeat zxid test
         */
        zxidSet = new HashSet<Long>();
        /**
         * Get config from zookeeper for address
         */
        config = new QuorumPeerConfig();
        CHANNEL = "aeron:udp?endpoint=225.0.0.3:40123|interface=" + config.getInterfaceAddr();
        mdCtx = new MediaDriver.Context()
                .termBufferSparseFile(false)
                .useWindowsHighResTimer(true)
                .threadingMode(ThreadingMode.DEDICATED)
                .conductorIdleStrategy(BusySpinIdleStrategy.INSTANCE)
                .receiverIdleStrategy(NoOpIdleStrategy.INSTANCE)
                .senderIdleStrategy(NoOpIdleStrategy.INSTANCE);
        driver = MediaDriver.launchEmbedded(mdCtx);
        ctx = new Aeron.Context();
        ctx.aeronDirectoryName(driver.aeronDirectoryName());
        
        /**
         * Start Aeron session
         */
        aeron = Aeron.connect(ctx);
        publication = aeron.addPublication(CHANNEL, STREAM_ID);
        buffer = new UnsafeBuffer(BufferUtil.allocateDirectAligned(1048576, 64));

        /**
         * Hello to receivers
         */
        long result;
        do {
            final int length = buffer.putStringWithoutLengthAscii(0, "HELLO");
            result = publication.offer(buffer, 0, length);
            try {
                Thread.sleep(100);
                LOG.warn("Followers not connected! Retry...");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        } while (result <= 0);
        LOG.info("Followers has connected!");
        SigInt.register(()->{
            publication.close();
            aeron.close();
        });
    }

    public void addPacketToSend(QuorumPacket p) {
        synchronized (this) {
            if (!zxidSet.contains(p.getZxid())) {
                zxidSet.add(p.getZxid());

                // send packet by Aeron channel
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                oa = new BinaryOutputArchive(new DataOutputStream(os));
                try {
                    oa.writeRecord(p, "packet");
                } catch (IOException e) {
                    e.printStackTrace();
                }
                byte[] data = os.toByteArray();
                buffer.putBytes(0, data);
                long result = publication.offer(buffer, 0, data.length);

                // Resend packet if not successed
                if (result <= 0) {
                    LOG.warn("Send failed! return {}", getReason(result));
                    for (int i=0; i<8 && result <= 0; i++) {
                        LOG.warn("Retried {} times...", i);
                        buffer.putBytes(0, data);
                        result = publication.offer(buffer, 0, data.length);
                        try {
                            Thread.sleep(50);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        LOG.warn("Resend! return {}", getReason(result));
                    }
                    LOG.warn("Retried 8 times, giving up...");
                }
            }
        }
    }

    private String getReason(long result) {
        if (result < 0L) {
            if (result == Publication.BACK_PRESSURED) {
                return new String("Offer failed due to back pressure");
            }
            else if (result == Publication.NOT_CONNECTED) {
                return new String(" Offer failed because publisher is not connected to subscriber");
            }
            else if (result == Publication.ADMIN_ACTION) {
                return new String("Offer failed because of an administration action in the system");
            }
            else if (result == Publication.CLOSED) {
                return new String("Offer failed publication is closed");
            }
            else if (result == Publication.MAX_POSITION_EXCEEDED) {
                return new String("Offer failed due to publication reaching max position");
            }
            else {
                return new String(" Offer failed due to unknown reason");
            }
        } else {
            return new String("No problem");
        }
    }

    public void shutdown() {
        publication.close();
        aeron.close();
    }
}