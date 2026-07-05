#!/usr/bin/env bash
# sunshine-steam-bigpicture.sh — launch Steam Big Picture and force-focus its window.
#
# Big Picture only reacts to gamepad input while its window has keyboard focus.
# When sunshine-headless-display.sh disables the physical monitors, their windows
# migrate onto the headless output and one of them can keep focus over BP, which
# leaves the streamed gamepad connected-but-dead. Explicitly focusing BP after it
# maps makes controller navigation deterministic.
#
# Use as the Sunshine app's detached command (absolute path):
#   /home/<you>/.config/sunshine/scripts/sunshine-steam-bigpicture.sh

set -uo pipefail

BP_TITLE="Steam Big Picture Mode"
LOG="/tmp/sunshine-vdisplay.log"

log(){ printf '%s [bigpicture] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG" >&2; }

# --- Reach the live Hyprland instance even when Sunshine doesn't carry its env ---
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  pid="$(pgrep -x Hyprland | head -n1)"
  if [ -n "$pid" ] && [ -r "/proc/$pid/environ" ]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')"
  fi
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || \
    HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -n1)"
  export HYPRLAND_INSTANCE_SIGNATURE
fi

setsid steam steam://open/bigpicture >/dev/null 2>&1 &

# Wait for the BP window to map (Steam may still be cold-starting), then focus it.
for _ in $(seq 1 30); do
  if hyprctl clients 2>/dev/null | grep -q "$BP_TITLE"; then
    hyprctl dispatch focuswindow "title:^(${BP_TITLE})\$" >/dev/null 2>&1
    log "Big Picture focused"
    exit 0
  fi
  sleep 1
done
log "WARNING: Big Picture window never appeared; focus not set"
exit 0
