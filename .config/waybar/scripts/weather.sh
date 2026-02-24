#!/bin/bash
CACHE="$HOME/.cache/waybar-weather"
FORECAST_CACHE="$HOME/.cache/waybar-weather-forecast"
API_URL="https://api.open-meteo.com/v1/forecast?latitude=-41.52&longitude=146.66&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code&timezone=Australia/Hobart&forecast_days=2"

# Output cached value or placeholder immediately
if [ -f "$CACHE" ]; then
    cat "$CACHE"
else
    echo "..."
fi

weather_emoji() {
    local code=$1 hour=$2
    local is_night=false
    if [ "$hour" -ge 20 ] || [ "$hour" -lt 6 ]; then
        is_night=true
    fi

    case $code in
        0)
            if $is_night; then echo "🌙"; else echo "☀️"; fi ;;
        1|2)
            if $is_night; then echo "☁️"; else echo "⛅"; fi ;;
        3) echo "☁️" ;;
        45|48) echo "🌫️" ;;
        51|53|55) echo "🌦️" ;;
        56|57|61|63|65|66|67) echo "🌧️" ;;
        71|73|75|77) echo "🌨️" ;;
        80|81|82) echo "🌦️" ;;
        85|86) echo "🌨️" ;;
        95|96|99) echo "⛈️" ;;
        *) echo "❓" ;;
    esac
}

# Fetch updated weather in background
(
    json=$(curl -s --max-time 10 "$API_URL" 2>/dev/null)
    if [ -n "$json" ] && echo "$json" | jq -e '.current' > /dev/null 2>&1; then
        code=$(echo "$json" | jq -r '.current.weather_code')
        temp=$(echo "$json" | jq -r '.current.temperature_2m | round')
        current_hour=$(date +%-H)
        emoji=$(weather_emoji "$code" "$current_hour")
        echo "${emoji} ${temp}°C" > "$CACHE"
        pkill -SIGRTMIN+8 waybar

        # Cache full JSON for the forecast click handler
        echo "$json" > "$FORECAST_CACHE"
    fi
) > /dev/null 2>&1 &
