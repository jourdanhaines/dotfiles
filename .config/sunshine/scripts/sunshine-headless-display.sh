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
PHYSICAL_OUTPUTS=("DP-1" "HDMI-A-1")    # names to `disable` while streaming
# Exact restore lines — MUST mirror the monitor= lines in hyprland.conf (DP-1, HDMI-A-1).
# We re-apply these explicitly because `hyprctl reload` does NOT re-enable a runtime-disabled
# monitor (Hyprland issue #6623), which is what left the panels dark and forced a reboot.
PHYSICAL_RESTORE=(
  "DP-1,3440x1440@143.85,0x0,1"
  "HDMI-A-1,3440x1440@84.96,0x-1440,1"
)
FALLBACK_MODE="3440x1440@60"
LOG="/tmp/sunshine-vdisplay.log"
###############################################################################

log(){ printf '%s [vdisplay] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG" >&2; }

# Deterministically bring the physical panels back. Never relies on `hyprctl reload`.
restore_physicals(){
  for line in "${PHYSICAL_RESTORE[@]}"; do hyprctl keyword monitor "$line" >/dev/null 2>&1; done
  hyprctl dispatch dpms on >/dev/null 2>&1
}

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

    # Size + focus the streaming output BEFORE dropping the panels, so there is never a
    # zero-enabled-output gap. Headless outputs take a plain mode (no real timings needed).
    if [ -n "$W" ] && [ -n "$H" ]; then
      hyprctl keyword monitor "$VIRTUAL_OUTPUT, ${W}x${H}@${FPS}, auto, 1" >/dev/null
    else
      hyprctl keyword monitor "$VIRTUAL_OUTPUT, $FALLBACK_MODE, auto, 1" >/dev/null
    fi
    hyprctl dispatch focusmonitor "$VIRTUAL_OUTPUT" >/dev/null 2>&1

    for m in "${PHYSICAL_OUTPUTS[@]}"; do hyprctl keyword monitor "$m, disable" >/dev/null; done
    log "streaming on $VIRTUAL_OUTPUT (${W:-?}x${H:-?}@${FPS})"
    ;;

  undo)
    log "restoring physical displays"
    restore_physicals                                    # explicit re-enable; never `hyprctl reload` (#6623)
    hyprctl keyword monitor "$VIRTUAL_OUTPUT, disable" >/dev/null 2>&1
    ;;

  *) echo "Usage: $0 {do|undo}" >&2; exit 2 ;;
esac
