#!/bin/bash

TMUX_BIN="/opt/homebrew/bin/tmux"

# Start tmux or attach to existing session
if [ -x "$TMUX_BIN" ]; then
    # Check if a session exists
    if "$TMUX_BIN" has-session 2>/dev/null; then
        exec "$TMUX_BIN" attach
    else
        exec "$TMUX_BIN" new-session
    fi
fi

# Fallback to default shell if tmux isn't available
exec "${SHELL:-/bin/zsh}"
