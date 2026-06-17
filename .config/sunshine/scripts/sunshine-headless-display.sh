#!/usr/bin/env bash
# sunshine-headless-display.sh — Hyprland headless output for Sunshine streaming.
#   do    ensure a headless output exists, size it to the client resolution, power off physical monitors
#   undo  restore physical monitors (and re-park the headless via your hyprland.conf disable rule)
#
# Call it from Sunshine -> Configuration -> General -> Global Prep Command using
# ABSOLUTE paths (Sunshine won't expand ~ or $HOME, and mangles inline quoting):
#   do:    /home/<you>/.config/sunshine/scripts/sunshine-headless-display.sh do
#   undo:  /home/<you>/.config/sunshine/scripts/sunshine-headless-display.sh undo
#
# hyprland.conf:
#   exec-once = hyprctl output create headless sunshine
#   monitor   = sunshine, disable

set -uo pipefail

###############################################################################
VIRTUAL_NAME="sunshine"                 # arg passed to `hyprctl output create headless`
VIRTUAL_OUTPUT="sunshine"               # the RESULTING monitor name (confirm via `hyprctl monitors`)
PHYSICAL_OUTPUTS=("DP-1" "HDMI-A-1")
FALLBACK_MODE="3440x1440@60"
LOG="/tmp/sunshine-vdisplay.log"
###############################################################################

log(){ printf '%s [vdisplay] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG" >&2; }

# --- Reach the live Hyprland instance even when Sunshine doesn't carry its env ---
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  # Read the signature straight from the running Hyprland process — robust against stale dirs.
  pid="$(pgrep -x Hyprland | head -n1)"
  if [ -n "$pid" ] && [ -r "/proc/$pid/environ" ]; then
    HYPRLAND_INSTANCE_SIGNATURE="$(tr '\0' '\n' < "/proc/$pid/environ" | sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p')"
  fi
  # Fallback: newest instance dir.
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || \
    HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | head -n1)"
  export HYPRLAND_INSTANCE_SIGNATURE
fi
[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || { log "no running Hyprland instance found; aborting"; exit 1; }

# trailing space so DP-1 doesn't match DP-11, etc.
monitor_exists(){ hyprctl monitors all 2>/dev/null | grep -q "Monitor $1 "; }

case "${1:-}" in
  do)
    W="${SUNSHINE_CLIENT_WIDTH:-}"; H="${SUNSHINE_CLIENT_HEIGHT:-}"; FPS="${SUNSHINE_CLIENT_FPS:-60}"

    # Self-heal: recreate the headless output if it vanished (reboot / reload / restart).
    if ! monitor_exists "$VIRTUAL_OUTPUT"; then
      log "headless '$VIRTUAL_OUTPUT' missing; creating"
      hyprctl output create headless "$VIRTUAL_NAME" >/dev/null 2>&1
      sleep 0.3
    fi

    # SAFETY: never disable the real monitors unless the virtual one is actually present.
    if ! monitor_exists "$VIRTUAL_OUTPUT"; then
      log "ERROR: headless output unavailable. Leaving displays on, aborting."
      exit 1
    fi

    for m in "${PHYSICAL_OUTPUTS[@]}"; do hyprctl keyword monitor "$m, disable" >/dev/null; done

    # Headless outputs take a plain mode (no real timings needed), matching what worked for you.
    if [ -n "$W" ] && [ -n "$H" ]; then
      hyprctl keyword monitor "$VIRTUAL_OUTPUT, ${W}x${H}@${FPS}, auto, 1" >/dev/null
    else
      hyprctl keyword monitor "$VIRTUAL_OUTPUT, $FALLBACK_MODE, auto, 1" >/dev/null
    fi
    hyprctl dispatch focusmonitor "$VIRTUAL_OUTPUT" >/dev/null 2>&1
    log "streaming on $VIRTUAL_OUTPUT (${W:-?}x${H:-?}@${FPS})"
    ;;

  undo)
    log "restoring physical displays"
    hyprctl reload >/dev/null 2>&1                       # restores physicals + re-parks headless via monitor=...,disable
    hyprctl keyword monitor "$VIRTUAL_OUTPUT, disable" >/dev/null 2>&1
    hyprctl dispatch dpms on >/dev/null 2>&1
    ;;

  *) echo "Usage: $0 {do|undo}" >&2; exit 2 ;;
esac
