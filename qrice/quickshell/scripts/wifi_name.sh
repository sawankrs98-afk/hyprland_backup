#!/bin/bash
while true; do
    NAME=$(iwgetid -r)
    if [ -z "$NAME" ]; then
        echo "Disconnected"
    else
        echo "$NAME"
    fi
    sleep 2
done
