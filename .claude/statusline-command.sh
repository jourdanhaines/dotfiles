#!/usr/bin/env bash
# Claude Code status line — styled after Starship Catppuccin Mocha config
#
# Segment order: [model ctx] → [dir] → [git] → [caveman?]
#
# CAVEMAN MODE DETECTION
# The caveman plugin (JuliusBrussee/caveman) injects its behaviour via a
# system-reminder at prompt time. It does NOT surface in the Claude Code
# status JSON — neither output_style.name nor any other known field reflects
# it. Until the Claude Code JSON schema exposes a plugin/skill state field,
# caveman mode cannot be auto-detected from the status line input.
# Workaround: set the environment variable CAVEMAN_MODE=1 in your shell
# (e.g. in ~/.zshrc) to force the badge on, or unset it to hide it.

input=$(cat)

# ---------------------------------------------------------------------------
# Catppuccin Mocha palette — background segments
# ---------------------------------------------------------------------------
BG_SURFACE0="\033[48;2;49;50;68m"
BG_PEACH="\033[48;2;232;145;90m"
BG_GREEN="\033[48;2;166;227;161m"
BG_TEAL="\033[48;2;148;226;213m"
BG_SKY="\033[48;2;137;220;235m"
BG_BLUE="\033[48;2;137;180;250m"
BG_PURPLE="\033[48;2;245;194;231m"
BG_RED="\033[48;2;243;139;168m"

# Foreground colours matching each background for powerline separators
FG_SURFACE0="\033[38;2;49;50;68m"
FG_PEACH="\033[38;2;232;145;90m"
FG_GREEN="\033[38;2;166;227;161m"
FG_TEAL="\033[38;2;148;226;213m"
FG_SKY="\033[38;2;137;220;235m"
FG_BLUE="\033[38;2;137;180;250m"
FG_PURPLE="\033[38;2;245;194;231m"
FG_RED="\033[38;2;243;139;168m"

# Dark foreground for text on coloured backgrounds (Catppuccin mantle)
FG_DARK="\033[38;2;24;24;37m"
# Light foreground for text on dark backgrounds (Catppuccin text)
FG_LIGHT="\033[38;2;205;214;244m"

RESET="\033[0m"

# Nerd Font glyphs (explicit escapes to avoid byte corruption)
ICON_FOLDER=$'\uf07b'        #
ICON_GIT=$'\ue725'           #
SEP_RIGHT=$'\ue0b0'          #  powerline right arrow
CAP_LEFT=$'\ue0b6'           #  powerline left round cap
CAP_RIGHT=$'\ue0b4'          #  powerline right round cap
ICON_ARCH=$'\uf303'          #  arch (nf-linux-archlinux)
ICON_CLOCK=$'\uf017'         #  clock

# ---------------------------------------------------------------------------
# Data extraction
# ---------------------------------------------------------------------------
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# Basename only — matches Starship's single-segment display
short_dir=$(basename "$dir")

# Strip any trailing parenthetical suffix from the model name, e.g. "(1M context)"
model_raw=$(echo "$input" | jq -r '.model.display_name // ""')
model=$(echo "$model_raw" | sed 's/ *([^)]*)$//')

# Git info — skip index locks to avoid blocking
git_branch=$(git -C "$dir" --no-optional-locks branch --show-current 2>/dev/null || true)
git_dirty=""
git_ahead=""
git_behind=""
if [ -n "$git_branch" ]; then
  dirty_count=$(git -C "$dir" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$dirty_count" -gt 0 ] && git_dirty=" !${dirty_count}"
  ahead=$(git -C "$dir" --no-optional-locks rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "0")
  behind=$(git -C "$dir" --no-optional-locks rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "0")
  [ "$ahead" -gt 0 ] && git_ahead=" ⇡${ahead}"
  [ "$behind" -gt 0 ] && git_behind=" ⇣${behind}"
fi

# Context window
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Caveman mode — env var fallback (see comment at top of file)
is_caveman=false
[ "${CAVEMAN_MODE:-0}" = "1" ] && is_caveman=true

# ---------------------------------------------------------------------------
# Segment: user  [blue bg] — always first
# ---------------------------------------------------------------------------
printf "${FG_SURFACE0}${CAP_LEFT}${RESET}${BG_SURFACE0}${FG_BLUE}${ICON_ARCH} ${FG_LIGHT}${USER} ${RESET}"
prev_fg="$FG_SURFACE0"

# ---------------------------------------------------------------------------
# Segment: directory  [peach bg]
# ---------------------------------------------------------------------------
printf "${prev_fg}${BG_PEACH}${SEP_RIGHT}${RESET}${BG_PEACH}${FG_DARK} ${ICON_FOLDER} ${short_dir} ${RESET}"
prev_fg="$FG_PEACH"

# ---------------------------------------------------------------------------
# Segment: git  [green bg] — only when inside a repo
# ---------------------------------------------------------------------------
if [ -n "$git_branch" ]; then
  git_label=" ${ICON_GIT} ${git_branch}${git_dirty}${git_ahead}${git_behind} "
  printf "${FG_PEACH}${BG_GREEN}${SEP_RIGHT}${RESET}${BG_GREEN}${FG_DARK}${git_label}${RESET}"
  prev_fg="$FG_GREEN"
fi

# ---------------------------------------------------------------------------
# Segment: model  [sky bg]
# ---------------------------------------------------------------------------
if [ -n "$model" ]; then
  printf "${prev_fg}${BG_SKY}${SEP_RIGHT}${RESET}${BG_SKY}${FG_DARK} [${model}]${RESET}"
  prev_fg="$FG_SKY"
fi

# ---------------------------------------------------------------------------
# Segment: context usage  [blue bg]
# ---------------------------------------------------------------------------
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  printf "${prev_fg}${BG_BLUE}${SEP_RIGHT}${RESET}${BG_BLUE}${FG_DARK}${used_int}%% used ${RESET}"
  prev_fg="$FG_BLUE"
fi

# ---------------------------------------------------------------------------
# Segment: caveman mode  [red bg] — only when CAVEMAN_MODE=1
# ---------------------------------------------------------------------------
if [ "$is_caveman" = true ]; then
  printf "${prev_fg}${BG_RED}${SEP_RIGHT}${RESET}${BG_RED}${FG_DARK} CAVEMAN ${RESET}"
  prev_fg="$FG_RED"
fi

# ---------------------------------------------------------------------------
# Segment: time  [purple bg]
# ---------------------------------------------------------------------------
time_now=$(date +%H:%M)
printf "${prev_fg}${BG_PURPLE}${SEP_RIGHT}${RESET}${BG_PURPLE}${FG_DARK} ${ICON_CLOCK} ${time_now} ${RESET}${FG_PURPLE}${CAP_RIGHT}${RESET}"

printf "\n"
