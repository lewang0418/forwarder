#!/bin/bash
ctx logger info "stop UDP forwarder"

set -e
PID=$(ctx instance runtime_properties udp_forwarder_pid)
kill -9 ${PID}
ctx logger info "Sucessfully stopped UDP forwarder (${PID})"
