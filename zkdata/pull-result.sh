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

sshpass -p $password scp $username@$h9:~/zookeeper/zk-test/*.log ./data
sshpass -p $password scp $username@$h10:~/zookeeper/zk-test/*.log ./data
sshpass -p $password scp $username@$h12:~/zookeeper/zk-test/*.log ./data
