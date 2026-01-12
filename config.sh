#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Copying config from $SCRIPT_DIR/.config/ghostty to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/ghostty"
cp -r "$SCRIPT_DIR/.config/ghostty" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/hypr to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/hypr"
cp -r "$SCRIPT_DIR/.config/hypr" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/lazydocker to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/lazydocker"
cp -r "$SCRIPT_DIR/.config/lazydocker" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/nvim to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/nvim"
cp -r "$SCRIPT_DIR/.config/nvim" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/tmux to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/tmux"
cp -r "$SCRIPT_DIR/.config/tmux" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/starship to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/starship"
cp -r "$SCRIPT_DIR/.config/starship" "$HOME/.config/"

echo ".config dotfiles copied from $SCRIPT_DIR/.config/ to $HOME/.config/"

