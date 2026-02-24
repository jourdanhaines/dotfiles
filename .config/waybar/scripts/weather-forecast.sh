#!/bin/bash
# Sends a styled dunst notification with the hourly weather forecast for the next 8 hours

FORECAST_CACHE="$HOME/.cache/waybar-weather-forecast"
API_URL="https://api.open-meteo.com/v1/forecast?latitude=-41.52&longitude=146.66&current=temperature_2m,weather_code&hourly=temperature_2m,weather_code&timezone=Australia/Hobart&forecast_days=2"

# Usage: weather_emoji <wmo_code> <hour>
# Hour (0-23) determines day/night variants for clear/partly cloudy
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

# Read from cache if available, otherwise fetch synchronously
if [ -f "$FORECAST_CACHE" ]; then
    json=$(<"$FORECAST_CACHE")
else
    json=$(curl -s --max-time 10 "$API_URL" 2>/dev/null)
    if [ -z "$json" ] || ! echo "$json" | jq -e '.hourly' > /dev/null 2>&1; then
        dunstify -h string:x-dunst-stack-tag:weather-forecast "Weather Forecast" "Failed to fetch weather data"
        exit 1
    fi
    echo "$json" > "$FORECAST_CACHE"
fi

# Refresh cache in background for next click
(
    fresh=$(curl -s --max-time 10 "$API_URL" 2>/dev/null)
    if [ -n "$fresh" ] && echo "$fresh" | jq -e '.hourly' > /dev/null 2>&1; then
        echo "$fresh" > "$FORECAST_CACHE"
    fi
) > /dev/null 2>&1 &

# Extract next 8 hours of data
now=$(date +%Y-%m-%dT%H:00)
readarray -t entries < <(echo "$json" | jq -r --arg now "$now" '
    .hourly | [.time, .temperature_2m, .weather_code] | transpose |
    map(select(.[0] >= $now)) | .[0:8] |
    .[] | "\(.[0])|\(.[1])|\(.[2])"
')

if [ ${#entries[@]} -eq 0 ]; then
    dunstify -h string:x-dunst-stack-tag:weather-forecast "Weather Forecast" "No forecast data available"
    exit 1
fi

# Build vertical list: one line per hour (time | emoji | temp)
# Each line has identical structure so columns align perfectly:
#   - Time: right-justified in 5 chars (monospace)
#   - Emoji: same display width across all lines (inline 16pt)
#   - Temp: right-justified in 2 chars (monospace)
body="<span font_desc='JetBrains Mono 10'>"
first=true

for entry in "${entries[@]}"; do
    IFS='|' read -r time temp code <<< "$entry"
    [ -z "$time" ] && continue

    hour=$(date -d "$time" +%-H)
    emoji=$(weather_emoji "$code" "$hour")
    temp=$(printf "%.0f" "$temp")
    time_str=$(date -d "$time" +"%l %p" | xargs)

    printf -v time_col "%5s" "$time_str"
    printf -v temp_col "%2s°" "$temp"

    if [ "$first" = true ]; then
        first=false
    else
        body+=$'\n'
    fi
    body+="<span foreground='#666666'>${time_col}</span>  <span font_size='16384'>${emoji}</span>  <b>${temp_col}</b>"
done

body+="</span>"

dunstify -h string:x-dunst-stack-tag:weather-forecast \
    "Weather — Next 8 Hours" \
    "$body"
