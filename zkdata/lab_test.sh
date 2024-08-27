#!/bin/bash

title="$1"
times=5
delay=10

echo "Warming up"
python3 run_client.py -t ${title}_test${i} -s -r 0.0
python3 run_client.py -d

echo "Wait ${delay} second to continue..."
sleep $delay

for ((i=1;i<=${times};i++))
do
    echo ${title}_test${i}
    python3 run_client.py -t ${title}_test${i} -s -r 0.0
    if [ ${i} != ${times} ]
    then
        echo "Wait ${delay} second to continue..."
        sleep $delay
    fi
done

./pull-result.sh

for ((i=1;i<=${times};i++))
do
    python3 data_process.py -i ${title}_test${i} -s
done

python3 data_process.py -i ${title}_test -b