#!/bin/bash

if [ "x$1" = "xdefault" ]
then
    zk_dir_name="apache-zookeeper-3.9.0-SNAPSHOT-bin"
    zk_arc_name="$zk_dir_name.tar.gz"
else
    zk_arc_name=$1
    arrIN=(${IN//./ })
    zk_dir_name=${arrIN[0]}
fi

if [ "x$2" = "x" ]
then
    echo "Please specify server's myid."
    exit 0
fi

rm -rf $zk_dir_name
tar -zxf $zk_arc_name
sudo rm -rf /tmp/zookeeper
sudo mkdir -p /tmp/zookeeper
sudo sh -c "echo $2 | cat > /tmp/zookeeper/myid"
cp zoo.cfg $zk_dir_name/conf/
ZKPATH=zk_dir_name
export ZKPATH