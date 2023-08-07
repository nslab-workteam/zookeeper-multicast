#!/bin/bash

zk_dir_name="apache-zookeeper-3.9.0-SNAPSHOT-bin"
zk_arc_name="$zk_dir_name.tar.gz"

function help() {
    echo "./zoohelper.sh -- helper to install and initalize zookeeper."
    echo "-h            This help message."
    echo "install ID    To install zookeeper, follow with id to this server."
    echo "run           To run zookeeper."
    echo "clear         Clean up zookeeper data."
}

function install() {
    if [ "x$1" == "x" ]
    then
        echo "Please provide ID."
        exit
    fi
    sudo rm -rf $zk_dir_name
    tar -zxf $zk_arc_name
    clear $1
}

function run() {
    sudo apache-zookeeper-3.9.0-SNAPSHOT-bin/bin/zkServer.sh start-foreground
}

function clear() {
    sudo rm -rf /tmp/zookeeper
    sudo mkdir -p /tmp/zookeeper
    sudo sh -c "echo $1 | cat > /tmp/zookeeper/myid"
    cp -f zoo_sample.cfg $zk_dir_name/conf/zoo.cfg
    ZKPATH=zk_dir_name
    export ZKPATH
}

if [ "x$1" == "xinstall" ]
then
    install $2
elif [ "x$1" == "xrun" ]
then
    run
elif [ "x$1" == "xclear" ]
then
    clear $2
else
    help
fi