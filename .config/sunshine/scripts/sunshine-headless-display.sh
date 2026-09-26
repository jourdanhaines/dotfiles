#!/usr/bin/env bash
# sunshine-headless-display.sh — Hyprland headless output for Sunshine streaming.
#   do    ensure a headless output exists, size it to the client resolution, power off physical monitors
#   undo  restore physical monitors (and re-park the headless via your hyprland.lua disable rule)
#
# Call it from Sunshine -> Configuration -> General -> Global Prep Command using
# ABSOLUTE paths (Sunshine won't expand ~ or $HOME, and mangles inline quoting):
#   do:    /home/<you>/.config/sunshine/scripts/sunshine-headless-display.sh do
#   undo:  /home/<you>/.config/sunshine/scripts/sunshine-headless-display.sh undo
#
# hyprland.lua:
#   hl.on("hyprland.start", function() hl.exec_cmd("hyprctl output create headless sunshine") end)
#   hl.monitor({ output = "sunshine", disabled = true })

set -uo pipefail

###############################################################################
VIRTUAL_NAME="sunshine"                 # arg passed to `hyprctl output create headless`
VIRTUAL_OUTPUT="sunshine"               # the RESULTING monitor name (confirm via `hyprctl monitors`)
PHYSICAL_OUTPUTS=("DP-1" "HDMI-A-1")    # names to `disable` while streaming
# hl.monitor() table bodies — MUST mirror the hl.monitor() lines in hyprland.lua.
# Re-applied explicitly because reload does not re-enable a runtime-disabled monitor.
# hl.monitor() merges into the existing rule, so `disabled = false` is needed to turn a panel back on.
PHYSICAL_RESTORE=(
  "output = 'DP-1',     mode = '3440x1440@143.85', position = '0x1440', scale = 1, disabled = false"
  "output = 'HDMI-A-1', mode = '3440x1440@84.96',  position = '0x0',    scale = 1, disabled = false"
)
FALLBACK_MODE="3440x1440@60"
LOG="/tmp/sunshine-vdisplay.log"
###############################################################################

log(){ printf '%s [vdisplay] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG" >&2; }

# Deterministically bring the physical panels back. Never relies on `hyprctl reload`.
restore_physicals(){
  local spec out m
  for spec in "${PHYSICAL_RESTORE[@]}"; do
    out="$(hyprctl eval "hl.monitor({ $spec })" 2>&1)"
    [ "$out" = "ok" ] || log "restore failed for [$spec]: $out"
  done
  for m in "${PHYSICAL_OUTPUTS[@]}"; do
    wait_enabled "$m" || log "WARNING: $m still disabled after restore"
  done
  hyprctl dispatch 'hl.dsp.dpms({ action = "enable" })' >/dev/null 2>&1
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
# `monitors all` also lists disabled outputs, so check the enabled state explicitly.
monitor_enabled(){ hyprctl -j monitors all 2>/dev/null | jq -e --arg n "$1" '.[] | select(.name==$n and .disabled==false)' >/dev/null; }
# Monitor changes via eval apply on a later compositor tick; poll instead of checking once.
wait_enabled(){ local i; for i in $(seq 1 30); do monitor_enabled "$1" && return 0; sleep 0.1; done; return 1; }
wait_disabled(){ local i; for i in $(seq 1 30); do monitor_enabled "$1" || return 0; sleep 0.1; done; return 1; }
wait_exists(){ local i; for i in $(seq 1 30); do monitor_exists "$1" && return 0; sleep 0.1; done; return 1; }

case "${1:-}" in
  do)
    W="${SUNSHINE_CLIENT_WIDTH:-}"; H="${SUNSHINE_CLIENT_HEIGHT:-}"; FPS="${SUNSHINE_CLIENT_FPS:-60}"

    # Self-heal: recreate the headless output if it vanished (reboot / reload / restart).
    if ! monitor_exists "$VIRTUAL_OUTPUT"; then
      log "headless '$VIRTUAL_OUTPUT' missing; creating"
      hyprctl output create headless "$VIRTUAL_NAME" >/dev/null 2>&1
      wait_exists "$VIRTUAL_OUTPUT" || true
    fi

    # SAFETY: never disable the real monitors unless the virtual one is actually present.
    if ! monitor_exists "$VIRTUAL_OUTPUT"; then
      log "ERROR: headless output unavailable. Leaving displays on, aborting."
      exit 1
    fi

    # Size + focus the streaming output BEFORE dropping the panels, so there is never a
    # zero-enabled-output gap. Headless outputs take a plain mode (no real timings needed).
    if [ -n "$W" ] && [ -n "$H" ]; then MODE="${W}x${H}@${FPS}"; else MODE="$FALLBACK_MODE"; fi
    out="$(hyprctl eval "hl.monitor({ output = '$VIRTUAL_OUTPUT', mode = '$MODE', position = 'auto', scale = 1, disabled = false })" 2>&1)"
    [ "$out" = "ok" ] || log "sizing failed for $VIRTUAL_OUTPUT ($MODE): $out"

    # SAFETY: the physical panels only go off once the headless output is actually enabled.
    if ! wait_enabled "$VIRTUAL_OUTPUT"; then
      log "ERROR: headless output failed to enable. Leaving displays on, aborting."
      exit 1
    fi
    hyprctl dispatch "hl.dsp.focus({ monitor = '$VIRTUAL_OUTPUT' })" >/dev/null 2>&1

    for m in "${PHYSICAL_OUTPUTS[@]}"; do
      out="$(hyprctl eval "hl.monitor({ output = '$m', disabled = true })" 2>&1)"
      [ "$out" = "ok" ] || log "disable failed for $m: $out"
    done
    log "streaming on $VIRTUAL_OUTPUT (${W:-?}x${H:-?}@${FPS})"
    ;;

  undo)
    log "restoring physical displays"
    restore_physicals                                    # explicit re-enable; reload won't do it
    hyprctl eval "hl.monitor({ output = '$VIRTUAL_OUTPUT', disabled = true })" >/dev/null 2>&1
    wait_disabled "$VIRTUAL_OUTPUT" || log "WARNING: $VIRTUAL_OUTPUT still enabled"
    ;;

  *) echo "Usage: $0 {do|undo}" >&2; exit 2 ;;
esac
