#!/bin/bash
username="p4user"
password="p4user"

zookeeper_path="zookeeper-assembly/target/apache-zookeeper-3.9.0-SNAPSHOT-bin.tar.gz"
to_send_path="to-send"
target_path="~/zookeeper"

h1="192.168.132.31"
h2="192.168.132.33"
h10="192.168.132.47"

sshpass -p $password scp $zookeeper_path $to_send_path/** $username@$h1:$target_path
sshpass -p $password scp $zookeeper_path $to_send_path/** $username@$h2:$target_path
sshpass -p $password scp $zookeeper_path $to_send_path/** $username@$h10:$target_path