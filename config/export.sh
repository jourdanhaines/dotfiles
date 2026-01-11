#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp -r "$SCRIPT_DIR/ghostty" "$HOME/.config/"
cp -r "$SCRIPT_DIR/hypr" "$HOME/.config/"
cp -r "$SCRIPT_DIR/lazydocker" "$HOME/.config/"
cp -r "$SCRIPT_DIR/nvim" "$HOME/.config/"
cp -r "$SCRIPT_DIR/tmux" "$HOME/.config/"

echo "Done!"

