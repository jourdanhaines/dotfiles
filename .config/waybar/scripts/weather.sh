#!/bin/bash
CACHE="$HOME/.cache/waybar-weather"

# Output cached value or placeholder immediately
if [ -f "$CACHE" ]; then
    cat "$CACHE"
else
    echo "..."
fi

# Fetch updated weather in background
(
    for i in 1 2 3; do
        weather=$(curl -s --max-time 5 "wttr.in/Deloraine+Tasmania?format=%c+%t" 2>/dev/null)
        if [ -n "$weather" ] && [ "$weather" != "Unknown location" ]; then
            weather=$(echo "$weather" | sed 's/+//g' | xargs)
            echo "$weather" > "$CACHE"
            pkill -SIGRTMIN+8 waybar
            exit 0
        fi
        sleep 5
    done
) > /dev/null 2>&1 &
