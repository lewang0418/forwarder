#!/bin/bash
ctx logger info "Start UDP forwarder"

exec > >(sudo tee -a /var/log/udp-forwarder-cloudify.log) 2>&1

FORWARDER_COMMAND="python /home/ubuntu/udp-forwarder.py ${host} ${port1} ${port2}"

ctx logger info "${FORWARDER_COMMAND}"
nohup ${FORWARDER_COMMAND} > /dev/null 2>&1 &
FORWARDER_PID=$!

ctx instance runtime_properties udp_forwarder_pid ${FORWARDER_PID}
ctx logger info "Sucessfully started UDP forwarder (${FORWARDER_PID})"


if [ ${enable_monitoring} = "true" ]; then
    ctx logger info "Start ELK"
    sudo service collectd start
    sudo service logstash start
fi
