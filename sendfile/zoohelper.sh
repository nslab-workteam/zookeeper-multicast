#!/bin/bash

zk_dir_name="apache-zookeeper-3.9.0-SNAPSHOT-bin"
zk_arc_name="$zk_dir_name.tar.gz"

zk_dir_ori_name="apache-zookeeper-3.7.1-bin"
zk_arc_ori_name="$zk_dir_ori_name.tar.gz"

AERON_VERSION="1.41.4"

original="false"

IN=$(hostname)
arrIN=(${IN//pm/ })
num=${arrIN[1]}

HOST_ID="${num#0}"

INTF=""
case ${HOST_ID} in
    1)
        INTF=enp2s0
        ;;
    2)
        INTF=enp1s0
        ;;
    3)
        INTF=enp1s0
        ;;
    4)
        INTF=enp2s0
        ;;
    9)
        INTF=enp2s0f1
        ;;
    10)
        INTF=enp1s0f1
        ;;
    12)
        INTF=enp1s0f1
        ;;
    *)
        echo "Wrong server id!"
        exit
esac
# case ${HOST_ID} in
#     1)
#         INTF=enx00e04c680646
#         ;;
#     2)
#         INTF=enx00e04c6806ce
#         ;;
#     3)
#         INTF=enx000ec66aec9c
#         ;;
#     4)
#         INTF=enx000ec66aedbd
#         ;;
#     9)
#         INTF=enx00e04c6803e7
#         ;;
#     10)
#         INTF=enx000ec6ac5190
#         ;;
#     12)
#         INTF=enx7cc2c649b625
#         ;;
#     *)
#         echo "Wrong server id!"
#         exit
# esac
echo "INTF=${INTF}"

echo "Welcome to use Zoohelper!"
echo "Running on host${HOST_ID}!"
sleep 1

function install() {
    if [ $original == "false"]
    then
        sudo rm -rf $zk_dir_name
        tar -zxf $zk_arc_name
        clear $zk_dir_name
    else
        install_original
    fi
}

function install_original() {
    sudo rm -rf $zk_dir_ori_name
    tar -zxf $zk_arc_ori_name
    clear $zk_dir_ori_name
}

function run() {
    sudo ZK_SERVER_HEAP=8192 $zk_dir_name/bin/zkServer.sh start-foreground
}

function run_media_driver() {
    sudo ~/zookeeper/aeron/cppbuild/Release/binaries/aeronmd \
        -Daeron.CongestionControl.supplier=aeron_cubic_congestion_control_strategy_supplier \
        -Daeron.print.configuration=true &
}

function kill_media_driver() {
    sudo kill -9 $(pgrep -f aeronmd)
    sudo rm -rf /dev/shm/aeron*
}

function run_original() {
    sudo ZK_SERVER_HEAP=8192 $zk_dir_ori_name/bin/zkServer.sh start-foreground
}

function clear() {
    # if [ "x$1" == "x" ]
    # then
    #     echo "Please provide ID."
    #     exit
    # fi
    sudo rm -rf /tmp/zookeeper
    sudo mkdir -p /tmp/zookeeper
    sudo sh -c "echo $HOST_ID | cat > /tmp/zookeeper/myid"
    cp -f zoo_sample.cfg $1/conf/zoo.cfg
    ZKPATH=$1
    export ZKPATH
}

function rate_limit() {
    echo set to ${2}mbit
    echo Removing...
    sudo tc qdisc del dev $1 root
    echo Adding...
    sudo tc qdisc add dev $1 root tbf rate ${2}mbit latency 50ms burst 1540
}

function rate_clear() {
    sudo tc qdisc del dev $1 root
}

function run_iperf() {
    case ${HOST_ID} in
        1)
            python3 bgtf.py -c 10.10.1.254 &
            ;;
        2)
            iperf3 -s 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.3 &
            ;;
        3)
            sleep 5
            iperf3 -u -c 10.10.1.2 -b 1.5G -t 10000 --bidir 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.2 &
            ;;
        4)
            iperf3 -s 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.9 &
            ;;
        9)
            sleep 5
            iperf3 -u -c 10.10.1.4 -b 1.5G -t 10000 --bidir 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.4 &
            ;;
        10)
            iperf3 -s 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.12 &
            ;;
        12)
            sleep 5
            iperf3 -u -c 10.10.1.10 -b 1.5G -t 10000 --bidir 2>&1 > /dev/null &
            python3 bgtf.py -c 10.10.1.12 &
            ;;
        *)
            echo "Wrong server id!"
            exit
    esac
}

function kill_iperf() {
    sudo kill -9 $(pgrep -f iperf3)
    sudo kill -9 $(pgrep -f bgtf.py)
}

function help() {
    echo "zoohelper.sh -- helper to install and initalize zookeeper."
    echo "-h                            This help message."
    echo "install                       To install zookeeper"
    echo "run                           To run zookeeper."
    echo "clear                         Clean up zookeeper data."
    echo "rate {add|del}                Add or clear tc rate limit rule."
    echo "[-o] ir                       Install [original] version."
    echo "run-md/kill-md                Run Media Driver or Kill Media Driver."
}

if [ "x$1" == "xinstall" ] || [ "x$1" == "xi" ]
then
    install
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
    install
    run
elif [ "x$2" == "xir" ] && [ "x$1" == "x-o" ]
then
    install_original
    run_original
elif [ "x$1" == "xrate" ]
then
    if [ "x$2" == "xadd" ]
    then
        rate_limit $INTF $3
    elif [ "x$2" == "xdel" ]
    then
        rate_clear $INTF
    else
        help
    fi
elif [ "x$1" == "xbgtf" ]
then
    if [ "x$2" == "xadd" ]
    then
        run_iperf
    elif [ "x$2" == "xdel" ]
    then
        kill_iperf
    else
        help
    fi
else
    help
fi