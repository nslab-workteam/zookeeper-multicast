import re
import csv
import argparse
import os

def logparser(filename) -> list:
    with open(filename) as f:
        data = f.readlines()
        
        durations = {}
        round_count = 0
        for i, line in enumerate(data):
            node_name, start_time, end_time = line.strip().split()
            round_count = int(re.findall(r'\d+', node_name)[0])
            if durations.get(round_count):
                durations[round_count][0] = min(durations[round_count][0], float(start_time))
                durations[round_count][1] = max(durations[round_count][1], float(end_time))
            else:
                durations[round_count] = [float(start_time), float(end_time)]

    return durations

def rw_parser(filename) -> (int, float, int, int):
    total = 0
    total_latency = 0
    total_bad = 0
    total_requests = 0
    count = 0
    with open(filename) as f:
        for line in f.readlines():
            if line.strip() != "":
                rps, latency, bad_count, req_count = line.strip().split()
                rps = float(rps)
                latency = float(latency)
                bad_count = int(bad_count)
                req_count = int(req_count)
                total += rps
                total_latency += latency
                total_bad += bad_count
                total_requests += req_count
                count += 1
    return total, total_latency / count, total_bad, total_requests

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="input file", required=True, type=str)
parser.add_argument("-s", "--stress", action="store_true")
parser.add_argument("-l", "--one-line", action='store_true', dest='one_line')
parser.add_argument("-b", "--bandwidth", action='store_true', dest='bandwidth')
parser.add_argument("-m", "--msg-size", action='store_true', dest='msgs')
args = parser.parse_args()

if args.one_line:
    input_files = os.listdir('csv/')
    input_files.sort()
    def getId(x):
        try:
            return float(re.findall(r"[01].[0-9]+", x)[-1])
        except:
            return 0
    input_files = sorted(input_files, key=getId)
    print(input_files)
    if all([False if re.findall(rf'{args.input}[0-9].[0-9]_.csv', filename) or \
            re.findall(rf'{args.input}[0-9]+_.csv', filename) else True for filename in input_files]):
        print(f"The {args.input}*.log is not found.")
        exit(-1)
    datas = [[] for _ in range(3)]
    for filename in input_files:
        if re.findall(rf'{args.input}[0-9].[0-9]_.csv', filename) or \
           re.findall(rf'{args.input}[0-9]+_.csv', filename):
            with open('csv/'+filename) as csvfile:
                reader = csv.reader(csvfile)
                for r in reader:
                    # print(r)
                    if r:
                        r = list(map(float, r))
                        datas[0].append(r[0])
                        datas[1].append(r[1])
                        datas[2].append(r[2])
    # print(datas)
    with open("csv/"+args.input+"_aio.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(datas)

elif args.stress:
    runtimes_collection = []
    latency_collection = []
    total_bad = 0
    total_requests = 0
    input_files = os.listdir("data/")
    if all([False if re.findall(rf'{args.input}[0-9]+.log', filename) else True for filename in input_files]):
        print(f"The {args.input}*.log is not found.")
        exit(-1)
    for filename in input_files:
        if re.findall(rf'{args.input}[0-9]+.log', filename):
            rps, latency, bad, requests = rw_parser("data/"+filename)
            runtimes_collection.append(rps)
            latency_collection.append(latency)
            total_bad += bad
            total_requests += requests
    with open("csv/"+args.input+".csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([f"{total_requests/30}", f"{sum(latency_collection)/len(latency_collection)}", f"{total_bad/total_requests}"])
elif args.bandwidth:
    input_files = os.listdir('csv/')
    input_files.sort()
    def getId(x):
        try:
            return int(re.findall(r"[0-9]+", x)[-1])
        except:
            return 0
    input_files = sorted(input_files, key=getId)
    print(input_files)
    # print(input_files)
    if not any([True if re.findall(rf'{args.input}[0-9]+.csv', filename) else False for filename in input_files]):
        print(f"The {args.input}*.log is not found.")
        exit(-1)
    datas = []
    for filename in input_files:
        if re.findall(rf'{args.input}[0-9]+.csv', filename):
            with open('csv/'+filename) as csvfile:
                reader = csv.reader(csvfile)
                for r in reader:
                    # print(r)
                    if r:
                        r = list(map(float, r))
                        datas.append(r)
    # print(datas)
    with open("csv/"+args.input+"_aio.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(datas)
elif args.msgs:
    input_files = os.listdir('csv/')
    input_files.sort()
    def getId(x):
        try:
            return int(re.findall(r"[0-9]+", x)[-1])
        except:
            return 0
    input_files = sorted(input_files, key=getId)
    print(input_files)
    if not any([True if re.findall(rf'{args.input}[0-9]+_.csv', filename) else False for filename in input_files]):
        print(f"The {args.input}*.log is not found.")
        exit(-1)
    datas = [[], [], []]
    for filename in input_files:
        if re.findall(rf'{args.input}[0-9]+_.csv', filename):
            with open('csv/'+filename) as csvfile:
                reader = csv.reader(csvfile)
                for r in reader:
                    print(r)
                    if r:
                        r = list(map(float, r))
                        datas[0].append(r[0])
                        datas[1].append(r[1])
                        datas[2].append(r[2])
    # print(datas)
    with open("csv/"+args.input+"_aio.csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(datas)
else:
    durations_collection = []
    input_files = os.listdir("data/")
    if all([False if re.findall(rf'{args.input}[0-9]+.log', filename) else True for filename in input_files]):
        print(f"The {args.input}*.log is not found.")
        exit(-1)
    for filename in input_files:
        if re.findall(rf'{args.input}[0-9]+.log', filename):
            durations_collection.append(logparser("data/"+filename))
                
    with open("csv/"+args.input+".csv", "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        for i in range(len(durations_collection[0])):
            writer.writerow([durations_collection[j][i][1] - durations_collection[j][i][0] for j in range(len(durations_collection))])
