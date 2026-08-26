#!/bin/bash
# Claude usage for waybar. `status` emits module JSON (session% / weekly%);
# `notify` fetches fresh data and shows a dunst breakdown of every limit.
# Reads the Claude Code OAuth token; never refreshes it (Claude Code owns rotation).

set -u
export LC_ALL=C.UTF-8  # ${#var} must count chars, not bytes (labels contain ·)

CRED="${CLAUDE_CRED_FILE:-$HOME/.claude/.credentials.json}"
CACHE="${XDG_RUNTIME_DIR:-/tmp}/waybar-claude-usage.json"
URL="https://api.anthropic.com/api/oauth/usage"
SIGNAL=10

DIM="#666666"
FONT="JetBrains Mono 10"

# Sets FETCH_ERR on failure. Returns 0 ok, 2 no creds, 3 expired/unauthorized, 4 other.
fetch() {
    FETCH_ERR=""
    if [ ! -r "$CRED" ]; then
        FETCH_ERR="No credentials at $CRED"
        return 2
    fi
    local token
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CRED" 2>/dev/null)
    if [ -z "$token" ]; then
        FETCH_ERR="No access token in credentials"
        return 2
    fi

    local tmp code body
    tmp=$(mktemp "${CACHE}.XXXXXX") || return 4
    code=$(curl -s --max-time 10 -o "$tmp" -w '%{http_code}' \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Accept: application/json" \
        "$URL" 2>/dev/null)

    if [ "$code" = "401" ] || [ "$code" = "403" ]; then
        rm -f "$tmp"
        FETCH_ERR="Token expired — open claude to refresh"
        return 3
    fi
    if [ "$code" != "200" ] || ! jq -e '.limits' "$tmp" >/dev/null 2>&1; then
        rm -f "$tmp"
        FETCH_ERR="Failed to fetch usage (HTTP ${code:-0})"
        return 4
    fi
    mv -f "$tmp" "$CACHE"
    return 0
}

# Usage: fmt_reset <iso timestamp> -> "in 2h 13m (14:19)" / "in 3d 5h (Sat 19:59)"
fmt_reset() {
    local iso=$1 end now rel abs rel_str
    end=$(date -d "$iso" +%s 2>/dev/null) || { echo "unknown"; return; }
    now=$(date +%s)
    rel=$(( end - now ))
    [ "$rel" -lt 0 ] && rel=0
    local d=$(( rel / 86400 )) h=$(( (rel % 86400) / 3600 )) m=$(( (rel % 3600) / 60 ))
    if [ "$d" -ge 1 ]; then
        rel_str="${d}d ${h}h"
    else
        rel_str="${h}h ${m}m"
    fi
    if [ "$(date -d "@$end" +%F)" = "$(date +%F)" ]; then
        abs=$(date -d "@$end" +%H:%M)
    else
        abs=$(date -d "@$end" +'%a %H:%M')
    fi
    echo "in ${rel_str} (${abs})"
}

# Pango-escape stdin.
esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

# Usage: pad <str> <width> — left-justify by character count (bash printf %-Ns pads by bytes).
pad() {
    local s=$1 w=$2
    printf '%s%*s' "$s" $(( w > ${#s} ? w - ${#s} : 0 )) ''
}

# Multi-line Pango body: one row per limit + reset line, plus extra-usage credits.
breakdown() {
    local json=$1 body="" line label pct reset
    while IFS='|' read -r label pct reset; do
        [ -z "$label" ] && continue
        [ -n "$body" ] && body+=$'\n'
        printf -v line '%s %3d%%' "$(pad "$label" 16)" "$pct"
        body+="$(printf '%s' "$line" | esc)"
        [ -n "$reset" ] && body+=$'\n'"<span foreground='${DIM}'>  resets $(fmt_reset "$reset")</span>"
    done < <(jq -r '
        .limits[]
        | (if .kind == "session" then "Session (5h)"
           elif .kind == "weekly_all" then "Weekly · all"
           elif .kind == "weekly_scoped" then "Weekly · \(.scope.model.display_name // "scoped")"
           else .kind end) as $label
        | "\($label)|\(.percent // 0)|\(.resets_at // "")"' <<< "$json")

    local extra used limit currency
    extra=$(jq -r '
        .extra_usage
        | select(.is_enabled == true)
        | "\(.used_credits // 0)|\(.monthly_limit // 0)|\(.currency // "")"' <<< "$json")
    if [ -n "$extra" ]; then
        IFS='|' read -r used limit currency <<< "$extra"
        printf -v line '%s %.2f / %s %s' "$(pad "Extra usage" 16)" "$used" "$limit" "$currency"
        body+=$'\n'"<span foreground='${DIM}'>$(printf '%s' "$line" | esc)</span>"
    fi
    printf "<span font_desc='%s'>%s</span>" "$FONT" "$body"
}

# Worst severity of session + weekly_all; falls back to percent thresholds.
severity_class() {
    jq -r '
        [.limits[] | select(.kind == "session" or .kind == "weekly_all")
         | (if .severity == "critical" or .percent >= 90 then 2
            elif .severity == "warning" or .percent >= 75 then 1
            else 0 end)]
        | max // 0
        | if . == 2 then "critical" elif . == 1 then "warning" else "normal" end' <<< "$1"
}

emit() {
    # $1 text, $2 tooltip, $3 class, $4 percentage
    jq -cn --arg t "$1" --arg tt "$2" --arg c "$3" --argjson p "${4:-0}" \
        '{text: $t, tooltip: $tt, class: $c, percentage: $p}'
}

status() {
    local cls json
    if fetch; then
        cls=""
    elif [ -r "$CACHE" ]; then
        cls="stale"
    else
        emit "-- / --" "$FETCH_ERR" "error" 0
        return
    fi
    json=$(<"$CACHE")
    local session weekly
    session=$(jq -r '[.limits[] | select(.kind == "session") | .percent][0] // 0' <<< "$json")
    weekly=$(jq -r '[.limits[] | select(.kind == "weekly_all") | .percent][0] // 0' <<< "$json")
    [ -z "$cls" ] && cls=$(severity_class "$json")
    local tip
    tip=$(breakdown "$json")
    [ "$cls" = "stale" ] && tip+=$'\n\n'"<span foreground='${DIM}'>$(printf '%s' "$FETCH_ERR" | esc)</span>"
    emit "${session}% / ${weekly}%" "$tip" "$cls" "$weekly"
}

notify() {
    if ! fetch; then
        dunstify -a waybar-claude -u critical -h string:x-dunst-stack-tag:claude-usage \
            "Claude Usage" "$(printf '%s' "$FETCH_ERR" | esc)"
        return 1
    fi
    dunstify -a waybar-claude -h string:x-dunst-stack-tag:claude-usage \
        "Claude Usage" "$(breakdown "$(<"$CACHE")")"
    pkill -RTMIN+$SIGNAL waybar 2>/dev/null || true
}

case "${1:-status}" in
    status) status ;;
    notify) notify ;;
    *) echo "usage: $0 [status|notify]" >&2; exit 1 ;;
esac
