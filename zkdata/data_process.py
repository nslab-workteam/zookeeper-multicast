import re
import csv
import argparse

def logparser(filename) -> list:
    with open(filename) as f:
        data = f.readlines()
        
        start_end = {}
        durations = []
        round_count = 0
        for i, line in enumerate(data):
            if i%3 == 0:
                node_name = re.findall(r'/[a-z]+[0-9]+[a-z]+', line.strip())[0]
                round_count = int(re.findall(r'\d+', node_name)[0])
                if not start_end.get(round_count, None):
                    start_end[round_count] = [0, 0]
            elif i%3 == 1:
                start_time = float(line.strip()[9:])
                if start_end[round_count][0] == 0:
                    start_end[round_count][0] = start_time
                # print("start", start_end[round_count][0])
            elif i%3 == 2:
                end_time = float(line.strip()[12:])
                start_end[round_count][1] = max(end_time, start_end[round_count][1])
                # print("end", start_end[round_count][1])

        for i, t in start_end.items():
            # print(f"{i}: {t[1]}, {t[0]}, {t[1] - t[0]}")
            durations.append(t[1] - t[0])
    return durations

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="input file", required=True, action='append')
args = parser.parse_args()

durations_collection = []
for filename in args.input:
    durations_collection.append(logparser(filename))
            
with open("csv/"+args.input[0].split("/")[-1]+".csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    for i, d in enumerate(durations_collection[0]):
        writer.writerow([dur[i] for dur in durations_collection])