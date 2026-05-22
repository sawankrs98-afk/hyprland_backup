#!/bin/bash
bluetoothctl devices Connected | awk "{print $3, $4, $5, $6}"
