#!/bin/bash
title="$1"
n_repeat=5
delay_time=10

function warmup() {
    echo "Warming up..."
    python3 run_client.py -t ${test_title}_warming --stress --read 0.0 -l 10K
    python3 run_client.py -d
    sleep ${delay_time}
}

function test() {
    test_title="$1"

    for i in $(seq 1 1 10)
    do
        echo "Testing ${i}K"
        python3 run_client.py -t ${test_title}${i}_ --stress --read 0.0 -l ${i}K
        if [ $i != 10 ]
        then
            echo "Wait ${delay_time} seconds before continue..."
            sleep ${delay_time}
        fi
    done
    ./pull-result.sh
    for i in $(seq 1 1 10)
    do
        python3 data_process.py -i ${test_title}${i}_ --stress
    done

    python3 data_process.py -i ${test_title} -m
}


warmup
for ((j=1;j<=${n_repeat};j++))
do
    echo "test_${j}_${title}"
    test test_${j}_${title}
    echo "Sleep 10 second."
    sleep 10
done