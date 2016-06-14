#!/bin/bash
sudo sed -i 's/127.0.0.1 localhost/127.0.0.1 localhost\n127.0.0.1 '$(cat /etc/hostname)'/g' /etc/hosts
yes '' | sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -q -y install oracle-java8-installer
sudo bash -c "echo JAVA_HOME=/usr/lib/jvm/java-8-oracle/ >> /etc/environment"
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
sudo service collectd restart
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
sudo service logstash restart
sudo apt-get -y install git
sudo apt-get -y install eclipse
