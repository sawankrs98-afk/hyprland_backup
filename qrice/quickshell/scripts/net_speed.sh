#!/bin/bash
INTERFACE=$(ip route | awk "/default/ {print $5}" | head -n1)
cat /sys/class/net/$INTERFACE/statistics/rx_bytes
