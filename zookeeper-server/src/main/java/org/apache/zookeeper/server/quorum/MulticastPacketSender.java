package org.apache.zookeeper.server.quorum;

public interface MulticastPacketSender {
    public void addPacketToSend(QuorumPacket p);
    public void shutdown();
}
