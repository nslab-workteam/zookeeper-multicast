#!/bin/bash
username="p4user"
password="p4user"

h1="192.168.132.31"
h2="192.168.132.32"
h3="192.168.132.33"
h4="192.168.132.34"
h9="192.168.132.46"
h10="192.168.132.47"
# h11="192.168.132.48"
h12="192.168.132.49"

hostlist=("$h1" "$h2" "$h3" "$h4" "$h9" "$h10" "$h11" "$h12")

function pull(){
    echo Pull log file: ${hostlist[$1]}
    sshpass -p $password scp $username@${hostlist[$1]}:~/zookeeper/data/*.log ./data
    echo ${hostlist[$1]} done
}

for ((i=0;i<8;i++))
do
    if [ "x${hostlist[$i]}" != "x" ]
    then
        pull $i &
    fi
done

wait