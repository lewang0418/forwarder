#!/bin/bash
ctx logger info "Start UDP forwarder"

exec > >(sudo tee -a /var/log/udp-forwarder-cloudify.log) 2>&1

COMMAND="python /home/ubuntu/udp-forwarder.py ${host} ${port1} ${port2}"

ctx logger info "${COMMAND}"
nohup ${COMMAND} > /dev/null 2>&1 &
PID=$!

ctx instance runtime_properties udp_forwarder_pid ${PID}
ctx logger info "Sucessfully started UDP forwarder (${PID})"

