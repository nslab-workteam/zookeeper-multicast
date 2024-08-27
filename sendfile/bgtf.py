import socket
import argparse

def server():
    s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    while (True):
        port = 10000
        try:
            s.bind(("0.0.0.0", port))
            print("Using port {}".format(port))
            break
        except:
            port += 1
    while (True):
        s.recvfrom(1408)

def client(server_ip, server_port=10000):
    if server_port == None: server_port = 10000
    s = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
    while (True):
        port = 10000
        try:
            s.bind(("0.0.0.0", port))
            break
        except:
            port += 1
    while (True):
        s.sendto(b'1234567890abcdefghij'*70, (server_ip, server_port))

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--server", action="store_true")
parser.add_argument("-p", "--port", type=int)
client_group = parser.add_argument_group()
client_group.add_argument("-c", "--client", action="store_true")
client_group.add_argument("server_ip", type=str)
args = parser.parse_args()

if args.server:
    server()
if args.client:
    client(args.server_ip, args.port)