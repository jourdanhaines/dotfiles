# dotfiles

Personal configs, deployed as **symlinks** — this repo is the single source of
truth. Edit a file here (or via its symlink in `~/.config`) and the change is
live immediately; `git status` here shows exactly what to push.

## Usage

```sh
./install.sh            # link all configs into ~/.config (+ tmux tpm, Claude statusline)
./install.sh --system   # additionally copy SDDM files to /etc and /usr/share (sudo)
```

Idempotent — safe to re-run on a fresh machine or after adding a new app.
Anything real found at a target path is moved to `<path>.bak.<timestamp>`,
never deleted.

## Adding a new app config

```sh
mkdir .config/<app>     # add config files here
./install.sh            # links ~/.config/<app> -> repo
```

No script changes needed — `install.sh` auto-discovers every directory under
`.config/`.

## How linking works

- **Default:** whole-dir symlink `~/.config/<app>` → `repo/.config/<app>`.
  New files added in the repo appear live with no re-run. For nvim this also
  means `lazy-lock.json` updates land directly in the repo.
- **Per-file exceptions (`PER_FILE` in install.sh): tmux, sunshine.** Their
  `~/.config/<app>` stays a real directory and only the repo's files are
  linked into it, because other tools write runtime data beside the config —
  tpm clones plugins into `tmux/plugins/`, Sunshine writes credentials, state,
  and `apps.json`. Those must stay out of the repo.
- **Per-OS skips (`SKIP`):** `aerospace` is macOS-only; Linux-only apps
  (hypr, waybar, etc.) are skipped on Darwin.
- **SDDM** (`etc/`, `share/`) is **copied**, not linked, via `--system` —
  SDDM reads its config as root before login, so symlinks into `/home` are
  fragile.
- **Claude statusline:** the script is symlinked; the `statusLine` key is
  jq-merged into `~/.claude/settings.json` (that file holds other machine
  state, so it can't be a symlink).
