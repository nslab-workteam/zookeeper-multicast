#!/bin/bash

zk_dir_name="apache-zookeeper-3.9.0-SNAPSHOT-bin"
zk_arc_name="$zk_dir_name.tar.gz"

if [ "x$1" = "x" ]
then
    echo "Please specify server's myid."
    exit 0
fi

rm -rf $zk_dir_name
tar -zxf $zk_arc_name
sudo rm -rf /tmp/zookeeper
sudo mkdir -p /tmp/zookeeper
sudo sh -c "echo $1 | cat > /tmp/zookeeper/myid"
cp zoo.cfg $zk_dir_name/conf/