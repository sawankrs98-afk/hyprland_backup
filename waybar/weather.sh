#!/usr/bin/env bash

LOCATION="Greater+Noida"

# Fetch data and strip raw newlines/carriage returns that break JSON
text=$(curl -s "https://wttr.in/${LOCATION}?format=%c+%t" | tr -d '\n\r')

# Fetch tooltip, convert newlines to literal \n for JSON, strip carriage returns
tooltip=$(curl -s "https://wttr.in/${LOCATION}?format=Location:+%l\nCondition:+%C+%c\nTemp:+%t+(Feels+like+%f)\nWind:+%w\nHumidity:+%h" | sed ':a;N;$!ba;s/\n/\\n/g' | tr -d '\r')

# Fallback if wttr.in is down, rate-limiting, or returns an HTML error
if [[ -z "$text" || "$text" == *"<html"* || "$text" == *"502"* || "$text" == *"503"* || "$text" == *"Unknown"* ]]; then
    text="󰖐 N/A"
    tooltip="Weather service temporarily unavailable"
fi

# Output strictly as a single-line JSON string
echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\"}"