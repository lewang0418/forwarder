# Usage
#chmod +x ./udp_forwarder.py
#./udp_forwarder.py 192.121.150.76 30120 30122

from socket import *
import sys, urllib, re, os
from cloudify import ctx
from cloudify.state import ctx_parameters as inputs

targetHost = inputs['host']
listenPort = int(inputs['port1'])
listenPort2 = int(inputs['port2'])

ctx.logger.info('Forwarder: {0} {1} {2}'.format(targetHost, listenPort, listenPort2))

f = os.popen('ifconfig eth0 | grep "inet\ addr" | cut -d: -f2 | cut -d" " -f1')

myip = f.read()

def get_external_ip():
    site = urllib.urlopen("http://checkip.dyndns.org/").read()
    grab = re.findall('([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)', site)
    address = grab[0]
    return address

bufsize = 4096 # Modify to suit your needs
#targetHost = sys.argv[1]
#listenPort = int(sys.argv[2])
#listenPort2 = int(sys.argv[3])

#myip=get_external_ip()
#myip=socket.gethostbyname(socket.gethostname())
print("listen on %s" % (myip))

def forward(data, port):
    sock = socket(AF_INET, SOCK_DGRAM)
    sock.bind((myip, port)) # Bind to the port data came in on
    sock.sendto(data, (targetHost, listenPort))

def listen(host, port):
    listenSocket = socket(AF_INET, SOCK_DGRAM)
    listenSocket.bind((host, port))
    while True:
        data, addr = listenSocket.recvfrom(bufsize)
        forward(data, addr[1]) # data and port

listen('0.0.0.0', listenPort)
listen('0.0.0.0', listenPort2)
