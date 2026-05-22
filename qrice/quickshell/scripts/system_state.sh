#!/bin/bash
while true; do
    # Get battery
    BAT_CAP=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "0")
    BAT_STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo "Unknown")
    
    # Get Bluetooth
    BT_DEV=$(bluetoothctl devices Connected | head -n1 | cut -d ' ' -f 3-)
    [ -z "$BT_DEV" ] && BT_DEV="Disconnected"
    
    # Output JSON
    echo "{\"bat\": \"$BAT_CAP\", \"charging\": \"$BAT_STATUS\", \"bt\": \"$BT_DEV\"}"
    sleep 2
done
