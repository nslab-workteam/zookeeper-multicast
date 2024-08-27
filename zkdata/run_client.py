#!/usr/bin/python3

import subprocess
import tempfile
import argparse
import time

username="p4user"
password="p4user"

host_dict = {
    "h1": "192.168.132.31",
    "h2": "192.168.132.32",
    "h3": "192.168.132.33",
    "h4": "192.168.132.34",
    "h9": "192.168.132.46",
    "h10": "192.168.132.47",
    # "h11": "192.168.132.48",
    "h12": "192.168.132.49",
}

title = 'tcp_420'
delete = True

def open_subprocess(hostname, thread_num, start):
    return subprocess.Popen(['/usr/bin/sshpass', '-p', password, 
                            'ssh', f'{username}@{hostname}', 
                            'sudo', 'docker', 'run', '-i', '--rm', '--net=host', '-v', '~/zookeeper/data:/src/data', '-v', '~/zookeeper/zk-test-tool/conf:/src/conf', '--name', 'zktest-instance-1', 'zktest', 
                            '100K', f'{thread_num}', '-I', host.split('h')[-1], '-s', str(start), title])

def open_stress_test(hostname, thread_num, start, read, length='5K'):
    id = host.split('h')[-1]
    cmd = f'/usr/bin/sshpass -p {password} ssh {username}@{hostname}\
            sudo docker run -i --rm --net=host -v ~/zookeeper/data:/src/data -v ~/zookeeper/zk-test-tool/conf:/src/conf --name zktest-instance-1 zktest\
            {length} {thread_num} -I {id} -s {start} {title} --stress --read {read}'
    return subprocess.Popen(cmd.split())


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--title', type=str)
    parser.add_argument('-d', '--delete', action='store_true')
    parser.add_argument('-s', '--stress', action='store_true')
    parser.add_argument('-r', '--read', type=float)
    parser.add_argument('-l', '--length', type=str)

    args = parser.parse_args()
    title = args.title
    delete = args.delete

    # print(title, delete)

    processes = []
    msg_size: str = args.length if args.length else '5K'
    for i, (host, hostname) in enumerate(host_dict.items()):
        if not delete:
            if args.stress:
                p = open_stress_test(hostname, 130, i*130, args.read, msg_size)
            else:
                p = open_subprocess(hostname, 60, i*60)
        else:
            p = subprocess.Popen((f'/usr/bin/sshpass -p {password} ssh {username}@{hostname} sudo docker rm -f zktest-instance-1 && sudo rm -rf ~/zookeeper/data/*.log').split())
        processes.append(p)
        
    for p in processes:
        p.wait()

    