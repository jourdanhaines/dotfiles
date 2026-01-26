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

if ! [ -d "$HOME/.config/tmux/plugins" ]; then
    echo "Installing tpm for tmux..."
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone "https://github.com/tmux-plugins/tpm" "$HOME/.config/tmux/plugins/tpm"
    echo "Cloned successfully!"
fi

echo "Copying config from $SCRIPT_DIR/.config/starship to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/starship"
cp -r "$SCRIPT_DIR/.config/starship" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/wofi to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/wofi"
cp -r "$SCRIPT_DIR/.config/wofi" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/fastfetch to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/fastfetch"
cp -r "$SCRIPT_DIR/.config/fastfetch" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/waybar to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/waybar"
cp -r "$SCRIPT_DIR/.config/waybar" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/dunst to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/dunst"
cp -r "$SCRIPT_DIR/.config/dunst" "$HOME/.config/"

echo "Copying config from $SCRIPT_DIR/.config/aerospace to $HOME/.config/"
mkdir -p "$SCRIPT_DIR/.config/aerospace"
cp -r "$SCRIPT_DIR/.config/aerospace" "$HOME/.config/"

echo ".config dotfiles copied from $SCRIPT_DIR/.config/ to $HOME/.config/"

