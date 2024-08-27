#!/bin/bash
title="$1"
delay_time=10

echo "Warming up..."
python3 run_client.py -t ${title}_warming --stress --read 0.0
python3 run_client.py -d
sleep ${delay_time}

for i in $(seq 0.0 0.1 1.0)
do
    echo "Testing r=${i}"
    python3 run_client.py -t ${title}${i}_ --stress --read ${i}
    if [ $i != 1.0 ]
    then
        echo "Wait ${delay_time} seconds before continue..."
        sleep ${delay_time}
    fi
done
./pull-result.sh
for i in $(seq 0.0 0.1 1.0)
do
    python3 data_process.py -i ${title}${i}_ --stress
done

python3 data_process.py -i ${title} -l