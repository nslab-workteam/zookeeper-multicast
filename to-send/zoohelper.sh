#!/bin/bash

zk_dir_name="apache-zookeeper-3.9.0-SNAPSHOT-bin"
zk_arc_name="$zk_dir_name.tar.gz"

zk_dir_ori_name="apache-zookeeper-3.7.1-bin"
zk_arc_ori_name="$zk_dir_ori_name.tar.gz"

AERON_VERSION="1.41.4"

function help() {
    echo "./zoohelper.sh -- helper to install and initalize zookeeper."
    echo "-h                            This help message."
    echo "install ID                    To install zookeeper, follow with id to this server."
    echo "run                           To run zookeeper."
    echo "clear                         Clean up zookeeper data."
    echo "rate {add|del} INTERFACE      Add or clear tc rate limit rule."
    echo "-o ir                         Install original version."
}

function install() {
    if [ "x$1" == "x" ]
    then
        echo "Please provide ID."
        exit
    fi
    sudo rm -rf $zk_dir_name
    tar -zxf $zk_arc_name
    clear $1 $zk_dir_name
}

function install_original() {
    if [ "x$1" == "x" ]
    then
        echo "Please provide ID."
        exit
    fi
    sudo rm -rf $zk_dir_ori_name
    tar -zxf $zk_arc_ori_name
    clear $1 $zk_dir_ori_name
}

function run() {
    run_media_driver
    sudo $zk_dir_name/bin/zkServer.sh start-foreground
}

function run_media_driver() {
    sudo java -cp $zk_dir_name/lib/aeron-all-$AERON_VERSION.jar \
    --add-opens java.base/sun.nio.ch=ALL-UNNAMED \
    --add-opens java.base/java.util.zip=ALL-UNNAMED \
    -Daeron.CongestionControl.supplier=io.aeron.driver.ext.CubicCongestionControlSupplier \
    io.aeron.driver.MediaDriver &
}

function kill_media_driver() {
    sudo kill -2 $(pgrep -f io.aeron.driver.MediaDriver)
}

function run_original() {
    sudo $zk_dir_ori_name/bin/zkServer.sh start-foreground
}

function clear() {
    if [ "x$1" == "x" ]
    then
        echo "Please provide ID."
        exit
    fi
    sudo rm -rf /tmp/zookeeper
    sudo mkdir -p /tmp/zookeeper
    sudo sh -c "echo $1 | cat > /tmp/zookeeper/myid"
    cp -f zoo_sample.cfg $2/conf/zoo.cfg
    ZKPATH=$2
    export ZKPATH
}

function rate_limit() {
    sudo tc qdisc del dev $1 root
    sudo tc qdisc add dev $1 root tbf rate 1000mbit latency 50ms burst 1
}

function rate_clear() {
    sudo tc qdisc del dev $1 root
}

if [ "x$1" == "xinstall" ] || [ "x$1" == "xi" ]
then
    install $2
elif [ "x$1" == "xrun" ] || [ "x$1" == "xr" ]
then
    run
elif [ "x$1" == "xrun-md" ]
then
    echo "Running Media Driver in background!"
    run_media_driver
elif [ "x$1" == "xkill-md" ]
then
    kill_media_driver
elif [ "x$1" == "xir" ]
then
    install $2
    run
elif [ "x$2" == "xir" ] && [ "x$1" == "x-o" ]
then
    install_original $3
    run_original
elif [ "x$1" == "xrate" ]
then
    if [ "x$2" == "xadd" ]
    then
        if [ "x$3" != "x" ]
        then
            rate_limit $3
        else
            help
        fi
    elif [ "x$2" == "xdel" ]
    then
        if [ "x$3" != "x" ]
        then
            rate_clear $3
        else
            help
        fi
    else
        help
    fi
else
    help
fi