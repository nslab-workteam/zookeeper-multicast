#!/bin/bash
title="$1"
loop_time=5

for ((i=1;i<${loop_time}+1;i++))
do
    echo "test_${i}_${title}"
    ./aio.sh "test_${i}_${title}" > logs/test_${i}_${title}.log 2>&1
    echo "Sleep 10 second."
    sleep 10
done