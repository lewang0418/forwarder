#!/bin/bash
ctx logger info "installing UDP forwarder and ELK..."

# Install packages
sudo sed -i 's/127.0.0.1 localhost/127.0.0.1 localhost\n127.0.0.1 '$(cat /etc/hostname)'/g' /etc/hosts
yes '' | sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -q -y install oracle-java8-installer
sudo bash -c "echo JAVA_HOME=/usr/lib/jvm/java-8-oracle/ >> /etc/environment"
sudo apt-get install -y --force-yes build-essential python python-dev python-setuptools

# Install UDP forwarder
sudo -E bash -c 'cat > /home/ubuntu/udp-forwarder.py << EOF
#!/usr/bin/python
from socket import *
import sys
import urllib
import re
import os
f = os.popen('\''ifconfig eth0 | grep "inet\ addr" | cut -d: -f2 | cut -d" " -f1'\'')

myip = f.read()

def get_external_ip():
    site = urllib.urlopen("http://checkip.dyndns.org/").read()
    grab = re.findall('\''([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)'\'', site)
    address = grab[0]
    return address

bufsize = 4096 # Modify to suit your needs
targetHost = sys.argv[1]
listenPort = int(sys.argv[2])
listenport2 = int(sys.argv[3])
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

listen('\''0.0.0.0'\'', listenPort)
listen('\''0.0.0.0'\'', listenPort2)

EOF'

sudo chmod +x /home/ubuntu/udp-forwarder.py


#Install ELK
sudo apt-get -y install collectd collectd-utils
sudo chmod 777 /etc/collectd/collectd.conf
sudo cat > /etc/collectd/collectd.conf <<EOF
Hostname "$(cat /etc/hostname)"
LoadPlugin logfile
LoadPlugin interface
LoadPlugin load
LoadPlugin memory
LoadPlugin network

<Plugin "interface">
  Interface "eth0"
  IgnoreSelected false
</Plugin>

<Plugin network>
    Server "127.0.0.1"
</Plugin>
EOF
sudo chmod 755 /etc/collectd/collectd.conf

cd ~; wget https://download.elastic.co/logstash/logstash/packages/debian/logstash_1.5.4-1_all.deb
sudo dpkg -i logstash_1.5.4-1_all.deb
sudo chmod 777 /etc/logstash/conf.d/
sudo cat > /etc/logstash/conf.d/logstash.conf <<EOF
input {
  udp {
    port => 25826         # 25826 matches port specified in collectd.conf
    buffer_size => 1452   # 1452 is the default buffer size for Collectd
    codec => collectd { } # specific Collectd codec to invoke
    type => collectd
  }
}
output {
  elasticsearch {
    embedded => false
        host => "129.192.22.251"
        cluster  => "logstash"
    protocol => "http"
    codec => "json"
  }
}
EOF
sudo chmod 755 /etc/logstash/conf.d/

sudo service collectd stop
sudo service logstash stop


