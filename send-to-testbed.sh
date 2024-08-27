#!/bin/bash
username="p4user"
password="p4user"

zookeeper_path="zookeeper-assembly/target/apache-zookeeper-3.9.0-SNAPSHOT-bin.tar.gz"
to_send_path="sendfile"
target_path="~/zookeeper"

h1="192.168.132.31"
h2="192.168.132.32"
h3="192.168.132.33"
h4="192.168.132.34"
h9="192.168.132.46"
h10="192.168.132.47"
# h11="192.168.132.48"
h12="192.168.132.49"

hostlist=("$h1" "$h2" "$h3" "$h4" "$h9" "$h10" "$h11" "$h12")

function send_all(){
    echo Send to h$(($1+1)): ${hostlist[$1]}
    sshpass -p $password scp $zookeeper_path $to_send_path/** $username@${hostlist[$1]}:$target_path
    # sshpass -p $password scp $to_send_path/** $username@${hostlist[$1]}:$target_path
    echo h$(($1+1)) done
}

function send_config(){
    echo Send to h$(($1+1)): ${hostlist[$1]}
    # sshpass -p $password scp $zookeeper_path $to_send_path/** $username@${hostlist[$1]}:$target_path
    sshpass -p $password scp $to_send_path/** $username@${hostlist[$1]}:$target_path
    sshpass -p $password scp $to_send_path/host.conf $username@${hostlist[$1]}:~/zookeeper/zk-test-tool/conf/
    echo h$(($1+1)) done
}

for ((i=0;i<8;i++))
do
    if [ "x${hostlist[$i]}" != "x" ]
    then
        if [ "x$1" == "xall" ]
        then
            send_all $i &
        elif [ "x$1" == "xconf" ]
        then
            send_config $i &
        fi
    fi

done

wait
echo "All done"