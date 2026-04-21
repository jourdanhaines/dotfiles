#!/usr/bin/env bash
# Waybar countdown timer (three-module split: display + play/pause + stop).
#   display-main    - JSON for the HH:MM:SS readout
#   display-toggle  - JSON for the play/pause control
#   display-stop    - JSON for the stop control
#   toggle          - start (prompt if idle) / pause / resume
#   stop            - clear timer
#   set             - prompt for new duration and start
#
# State file format (single line):
#   idle
#   running <end_epoch_seconds>
#   paused  <remaining_seconds>
#   done    <finished_epoch_seconds>

set -u

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-timer.state"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/waybar-timer.lock"
ICON_CLOCK="󰔛"
ICON_REC="●"
ICON_PLAY="󰐊"
ICON_PAUSE="󰏤"
ICON_STOP="󰓛"
ICON_DONE="󰀨"

COLOR_REC="#e78284"      # red record dot
COLOR_DISABLED="#6c7086" # muted clock while paused
COLOR_DONE="#a6d189"     # green completed

read_state() {
  if [[ -r "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo "idle"
  fi
}

write_state() {
  printf '%s\n' "$1" >"$STATE_FILE"
}

format_hms() {
  local total=$1
  (( total < 0 )) && total=0
  local h=$(( total / 3600 ))
  local m=$(( (total % 3600) / 60 ))
  local s=$(( total % 60 ))
  printf '%02d:%02d:%02d' "$h" "$m" "$s"
}

parse_duration() {
  # Accept HH:MM:SS, MM:SS, SS, or suffixed "1h30m10s"/"30m"/"10s".
  local input="$1"
  input="${input//[[:space:]]/}"
  [[ -z "$input" ]] && return 1

  if [[ "$input" == *:* ]]; then
    IFS=':' read -r -a parts <<<"$input"
    local h=0 m=0 s=0
    case ${#parts[@]} in
      1) s=${parts[0]} ;;
      2) m=${parts[0]}; s=${parts[1]} ;;
      3) h=${parts[0]}; m=${parts[1]}; s=${parts[2]} ;;
      *) return 1 ;;
    esac
    [[ "$h" =~ ^[0-9]+$ && "$m" =~ ^[0-9]+$ && "$s" =~ ^[0-9]+$ ]] || return 1
    echo $(( h*3600 + m*60 + s ))
    return 0
  fi

  if [[ "$input" =~ ^([0-9]+h)?([0-9]+m)?([0-9]+s)?$ && -n "${BASH_REMATCH[0]}" ]]; then
    local h=${BASH_REMATCH[1]%h}
    local m=${BASH_REMATCH[2]%m}
    local s=${BASH_REMATCH[3]%s}
    echo $(( ${h:-0}*3600 + ${m:-0}*60 + ${s:-0} ))
    return 0
  fi

  if [[ "$input" =~ ^[0-9]+$ ]]; then
    echo "$input"
    return 0
  fi

  return 1
}

prompt_duration() {
  local val
  if command -v wofi >/dev/null 2>&1; then
    val=$(printf '' | wofi --dmenu --prompt "Timer (HH:MM:SS)" --lines 0 --width 300 --height 70 2>/dev/null)
  elif command -v zenity >/dev/null 2>&1; then
    val=$(zenity --entry --title="Timer" --text="Duration (HH:MM:SS):" 2>/dev/null)
  else
    return 1
  fi
  [[ -z "$val" ]] && return 1
  local secs
  secs=$(parse_duration "$val") || {
    notify-send -a "waybar-timer" -u critical "Timer" "Invalid duration: $val"
    return 1
  }
  (( secs > 0 )) || return 1
  echo "$secs"
}

now_epoch() { date +%s; }

signal_waybar() { pkill -RTMIN+9 waybar 2>/dev/null || true; }

start_with_seconds() {
  local secs=$1
  local end=$(( $(now_epoch) + secs ))
  write_state "running $end"
  signal_waybar
}

cmd_set() {
  local secs
  secs=$(prompt_duration) || exit 0
  start_with_seconds "$secs"
}

cmd_toggle() {
  local state
  state=$(read_state)
  local kind=${state%% *}
  local rest=${state#* }
  case "$kind" in
    idle|done)
      cmd_set
      ;;
    running)
      local end=$rest
      local remaining=$(( end - $(now_epoch) ))
      (( remaining < 0 )) && remaining=0
      write_state "paused $remaining"
      signal_waybar
      ;;
    paused)
      local remaining=$rest
      start_with_seconds "$remaining"
      ;;
  esac
}

cmd_stop() {
  write_state "idle"
  signal_waybar
}

emit() {
  # $1 text, $2 tooltip, $3 class
  printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' "$1" "$2" "$3" "$3"
}

# Reduce state to a single classifier + remaining seconds.
# Also handles "running -> done" transition (with notification).
resolve_state() {
  local state kind rest
  # Serialize the running→done transition so only one caller notifies.
  exec 9>"$LOCK_FILE"
  flock 9 2>/dev/null || true
  state=$(read_state)
  kind=${state%% *}
  rest=${state#* }

  case "$kind" in
    running)
      local end=$rest
      local remaining=$(( end - $(now_epoch) ))
      if (( remaining <= 0 )); then
        write_state "done $(now_epoch)"
        notify-send -a "waybar-timer" -u normal "Timer complete" "Your timer has finished." 2>/dev/null || true
        STATE_KIND="done"
        STATE_REMAINING=0
      else
        STATE_KIND="running"
        STATE_REMAINING=$remaining
      fi
      ;;
    paused)
      STATE_KIND="paused"
      STATE_REMAINING=$rest
      ;;
    done)
      STATE_KIND="done"
      STATE_REMAINING=0
      ;;
    *)
      STATE_KIND="idle"
      STATE_REMAINING=0
      ;;
  esac
  exec 9>&-
}

cmd_display_main() {
  resolve_state
  local icon_markup tip
  case "$STATE_KIND" in
    idle)
      icon_markup="$ICON_CLOCK"
      tip="Timer idle — click to set duration"
      ;;
    running)
      icon_markup="<span foreground='${COLOR_REC}'>${ICON_REC}</span>"
      tip="Running — click to set new duration"
      ;;
    paused)
      icon_markup="<span foreground='${COLOR_DISABLED}'>${ICON_REC}</span>"
      tip="Paused — click to set new duration"
      ;;
    done)
      icon_markup="<span foreground='${COLOR_DONE}'>${ICON_DONE}</span>"
      tip="Timer complete — click to set duration"
      ;;
  esac
  emit "${icon_markup} $(format_hms "$STATE_REMAINING")" "$tip" "$STATE_KIND"
}

cmd_display_toggle() {
  resolve_state
  local icon tip
  case "$STATE_KIND" in
    running) icon="$ICON_PAUSE"; tip="Pause timer" ;;
    paused)  icon="$ICON_PLAY";  tip="Resume timer" ;;
    *)       icon="$ICON_PLAY";  tip="Start timer" ;;
  esac
  emit "$icon" "$tip" "$STATE_KIND"
}

cmd_display_stop() {
  resolve_state
  emit "$ICON_STOP" "Stop timer" "$STATE_KIND"
}

case "${1:-display-main}" in
  display-main)   cmd_display_main ;;
  display-toggle) cmd_display_toggle ;;
  display-stop)   cmd_display_stop ;;
  toggle)         cmd_toggle ;;
  stop)           cmd_stop ;;
  set)            cmd_set ;;
  *) echo "usage: $0 {display-main|display-toggle|display-stop|toggle|stop|set}" >&2; exit 2 ;;
esac
