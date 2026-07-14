#!/usr/bin/env bash
#
# Symlinks every app config under .config/ into ~/.config so this repo is the
# single source of truth. Idempotent: safe to re-run any time (fresh machine,
# or after adding a new app dir). Existing real files are backed up, never
# deleted. Run with --system to also install SDDM files (needs sudo).

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Apps whose target dir must stay a real directory because other tools write
# runtime files beside the config (tpm clones, sunshine credentials/state).
# Their top-level entries are linked individually instead.
PER_FILE=(tmux sunshine)

case "$(uname -s)" in
    Darwin) SKIP=(hypr waybar wofi dunst sunshine fastfetch) ;;
    *)      SKIP=(aerospace) ;;
esac

in_list() {
    local x=$1; shift
    local i
    for i in "$@"; do [[ $i == "$x" ]] && return 0; done
    return 1
}

# link <repo-path> <target-path> — idempotent symlink with backup
link() {
    local src=$1 dst=$2
    if [[ -L $dst ]]; then
        [[ $(readlink "$dst") == "$src" ]] && { echo "ok      $dst"; return; }
        rm "$dst"
    elif [[ -e $dst ]]; then
        echo "backup  $dst -> $dst.bak.$STAMP"
        mv "$dst" "$dst.bak.$STAMP"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "link    $dst -> $src"
}

link_config_apps() {
    local dir app entry
    for dir in "$DOTFILES/.config"/*/; do
        app=$(basename "$dir")
        if in_list "$app" "${SKIP[@]}"; then
            echo "skip    $app (not for $(uname -s))"
            continue
        fi
        if in_list "$app" "${PER_FILE[@]}"; then
            mkdir -p "$HOME/.config/$app"
            for entry in "$dir"*; do
                link "$entry" "$HOME/.config/$app/$(basename "$entry")"
            done
        else
            link "${dir%/}" "$HOME/.config/$app"
        fi
    done
}

install_tpm() {
    [[ -d $HOME/.config/tmux/plugins/tpm ]] && return
    echo "Installing tpm for tmux..."
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone "https://github.com/tmux-plugins/tpm" "$HOME/.config/tmux/plugins/tpm"
}

install_claude() {
    mkdir -p "$HOME/.claude"
    link "$DOTFILES/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

    local settings="$HOME/.claude/settings.json"
    local cfg='{"statusLine":{"type":"command","command":"bash '"$HOME"'/.claude/statusline-command.sh"}}'
    if [[ -f $settings ]]; then
        local tmp
        tmp=$(mktemp)
        jq --argjson add "$cfg" '. * $add' "$settings" > "$tmp" && mv "$tmp" "$settings"
    else
        echo "$cfg" | jq . > "$settings"
    fi
    echo "Claude statusline configured in $settings"
}

# SDDM parses its config as root before login, so these are copied, not linked.
install_sddm() {
    echo "Installing SDDM config (sudo)..."
    sudo install -Dm644 "$DOTFILES/etc/sddm/sddm.conf" /etc/sddm/sddm.conf
    sudo install -Dm644 "$DOTFILES/share/sddm/themes/alpine/theme.conf.user" \
        /usr/share/sddm/themes/alpine/theme.conf.user
}

link_config_apps
install_tpm
install_claude
[[ ${1:-} == --system ]] && install_sddm

echo "Done. Any replaced configs were preserved as *.bak.$STAMP"
