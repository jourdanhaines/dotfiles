#!/bin/bash
BASE=$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu --format=csv,nounits,noheader 2>/dev/null \
  | sed -E 's/^([^,]+), *([0-9]+), *([0-9]+)/\1 \2% \3°C/g')

if [ -z "$BASE" ]; then
  echo "GPU N/A"
  exit 0
fi

# Max hotspot since boot; tmpfs so it clears on reboot
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-gpu-hotspot-max"
MAX=$(cat "$STATE" 2>/dev/null)
[[ "$MAX" =~ ^[0-9]+$ ]] || MAX=""

# Hotspot only comes from lact; timeout guards a hung daemon
HOTSPOT=$(timeout 1 lact cli stats 2>/dev/null | grep -oP 'GPU Hotspot: \K[0-9]+' | head -n1)

if [[ "$HOTSPOT" =~ ^[0-9]+$ ]]; then
  if [ -z "$MAX" ] || (( HOTSPOT > MAX )); then
    MAX=$HOTSPOT
    echo "$MAX" > "$STATE" 2>/dev/null
  fi
  echo "$BASE (${HOTSPOT}°C/${MAX}°C)"
elif [ -n "$MAX" ]; then
  echo "$BASE (N/A/${MAX}°C)"
else
  echo "$BASE (N/A)"
fi
