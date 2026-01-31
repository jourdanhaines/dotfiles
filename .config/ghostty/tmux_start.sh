#!/bin/bash

# Find tmux binary - check common locations for macOS and Linux
if [ -x "/opt/homebrew/bin/tmux" ]; then
    TMUX_BIN="/opt/homebrew/bin/tmux"
elif [ -x "/usr/local/bin/tmux" ]; then
    TMUX_BIN="/usr/local/bin/tmux"
elif command -v tmux >/dev/null 2>&1; then
    TMUX_BIN="$(command -v tmux)"
fi

# Start tmux or attach to existing session
if [ -n "$TMUX_BIN" ] && [ -x "$TMUX_BIN" ]; then
    # Check if a session exists
    if "$TMUX_BIN" has-session 2>/dev/null; then
        exec "$TMUX_BIN" attach
    else
        exec "$TMUX_BIN" new-session
    fi
fi

# Fallback to default shell if tmux isn't available
exec "${SHELL:-/bin/zsh}"
