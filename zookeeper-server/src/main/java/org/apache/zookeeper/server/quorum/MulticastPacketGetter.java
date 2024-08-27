package org.apache.zookeeper.server.quorum;

public interface MulticastPacketGetter{
    public byte[] getBytes() throws Exception;
    public void stopLoop();
}
