import socket
import argparse
import time

data = ''.join([chr(i) for i in range(32, 127)]).encode('utf-8')

def server(host, port):
    now = time.time()
    byte_counter = 0
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((host, port))
    while True:
        indata, addr = sock.recvfrom(1500)
        byte_counter += len(indata)
        if time.time() - now >= 1:
            print(f"{byte_counter * 8 / (10 ** 9)} Gbits/sec")
            now = time.time()
            byte_counter = 0
    sock.close()

def client(host, port):
    now = time.time()
    byte_counter = 0
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    print(f"To {host}:{port}")
    while True:
        sock.sendto(data, (host, port))
        byte_counter += len(data)
        if time.time() - now >= 1:
            print(f"{byte_counter * 8 / (10 ** 9)} Gbits/sec")
            now = time.time()
            byte_counter = 0
    sock.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', action='store_true')
    parser.add_argument('-c', action='store_true')
    parser.add_argument('host', type=str)
    parser.add_argument('-p', '--port', type=int)
    args = parser.parse_args()
    print(args)
    if args.s:
        server(args.host, args.port)
    if args.c:
        client(args.host, args.port)
