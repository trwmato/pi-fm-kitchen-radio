#!/bin/bash

bluetoothctl devices | while read -r _ MAC NAME; do
    INFO=$(bluetoothctl info "$MAC")

    echo "$INFO" | grep -q "Trusted: yes" || continue
    echo "$INFO" | grep -q "Connected: yes" || continue

    bluealsa-aplay -l | grep -q "$MAC" || continue

    echo "$MAC"
    exit 0
done

exit 1
