# bspwm dotfiles

*Read this in other languages:* [Español](README.es.md)

Standalone, public X11 desktop session based on bspwm, with Polybar, Rofi, Picom,
and Dunst. It can be installed completely without the base dotfiles, MangoWM,
Archcraft, or private configurations.

## Quickstart

On CachyOS or Arch Linux, clone the repository and enter it:

```bash
git clone https://github.com/anthonyportugal/bspwm.git
cd bspwm
```

CachyOS can use Shelly and its native Brave binary package. On generic Arch Linux,
install `paru` or `yay` first if you want the `desktop` profile to resolve the
`brave-bin` AUR fallback.

The first command executes a dry-run. Inspect the planned operations before applying:

```bash
./bin/bspwm bootstrap --profile desktop
./bin/bspwm bootstrap --profile desktop --apply
./bin/bspwm doctor --profile desktop
```

Afterward:

1. Log out of the current session;
2. Select `bspwm` in Ly or another display manager;
3. Log in;
4. Press `Super` to launch applications or `Super+X` for the power menu;
5. Use `Alt+Space` to toggle between `us` and `latam` keyboard layouts;
6. Use `Super+Ctrl+W` to open the interactive Rofi wallpaper selector.

Do not run the entire bootstrap with `sudo`. The backend elevates package
installation privileges internally; GNU Stow always runs as your regular user.

## Troubleshooting

### Picom in Virtual Machines

The default rendering backend is `glx`. Some virtual GPUs require `xrender`.
Create `~/.config/bspwm/local.env` with:

```bash
BSPWM_PICOM_BACKEND=xrender
```

Keep this setting local: the public repository does not hardcode hypervisor-specific
exceptions.

### Polybar

Logs are written to `$XDG_STATE_HOME/bspwm/polybar` (or `~/.local/state/bspwm/polybar`):

```bash
sed -n '1,160p' ~/.local/state/bspwm/polybar/*.log
```

`launcher.log` tracks automatic or explicit module resolution. Monitor-specific
files capture output from each Polybar instance. Concurrent launches are serialized
to prevent duplicate instances during startup.

Polybar detects network and battery interfaces by capabilities. If dynamic
discovery fails during boot, the launcher retries once with RAM, storage, and XKB
layout as a safe fallback set.

Override dynamic module selection via `local.env`:

```bash
BSPWM_POLYBAR_RIGHT='pulseaudio memory filesystem xkeyboard'
```

Explicit overrides take precedence and are never silently replaced.

### Quick Diagnostics

```bash
bspc query -M --names
bspc query -D --names
setxkbmap -query
pgrep -a 'sxhkd|xcape|polybar|picom|dunst|playerctld'
./bin/bspwm doctor --profile desktop
```

The profile installs `xorg-xauth`, required by display managers like Ly to
authorize X sessions in minimal installations.

## Packages Installed

Profiles are cumulative:

- `core`: Xorg, Xauth, XKB via `setxkbmap`, bspwm, sxhkd, GNU Stow, and minimal
  session configs;
- `desktop` (default): adds Polybar, Picom, Rofi, Dunst, `feh`, `xcape`, audio,
  screenshots, fonts, and utilities used by default shortcuts.

Automatic detection checks Shelly on CachyOS, then `paru`, `yay`, and `pacman`.
You can audit without modifying the host:

```bash
./bin/bspwm bootstrap --profile desktop --backend paru
./bin/bspwm bootstrap --profile core --packages-only
./bin/bspwm bootstrap --profile desktop --stow-only
```

Package manifests and origins are documented in [`packages/README.md`](packages/README.md).

## Managed Scope

This repository exclusively manages:

- `~/.config/bspwm` and bspwm window rules;
- sxhkd keybindings;
- XKB layouts for this X11 session, without modifying global system policies;
- Polybar, Picom, Dunst, and Rofi configurations;
- X11 helper scripts consumed by these components;
- Self-contained dependencies, bootstrap, and doctor validations.

It does not manage display managers, hybrid GPU drivers, secrets, wallpapers, or
private configurations. The `bspwm` package provides the session desktop entry
selectable by Ly.

Configurations preserve the Catppuccin visual experience, but remove any dependency
on `/etc/skel`, `/usr/share/archcraft`, Feather fonts, or hardcoded device names.

Alacritty is installed as the default terminal, but its configuration is managed
by the base dotfiles repository to allow seamless sharing between X11 and Wayland.

## Session Lifecycle & Features

- Eight workspaces distributed across detected outputs;
- Polybar launched per monitor with edge-to-edge layout and Catppuccin Pink accents;
- Native system tray docked in the center block next to the clock on primary output;
- Audio handled via PipeWire / WirePlumber (`wpctl`);
- Media MPRIS control via `mpv-mpris` and Playerctl;
- Screenshots saved to `Pictures/Screenshots` and copied to clipboard via Xclip;
- Power menu accessible via `Super+X`;
- Interactive wallpaper selector with `Super+Ctrl+W` scanning `~/Pictures/Wallpapers`;
- Picom provides subtle rounded corners and dimming for inactive windows;
- Runtime state or hardware detection never mutates versioned checkout files.

### Primary Keybindings

| Shortcut | Action |
| --- | --- |
| `Super` | Application launcher (Rofi) |
| `Super+Enter` | Terminal |
| `Super+Shift+Enter` | Floating terminal |
| `Super+D` / `Alt+F1` | Application launcher |
| `Alt+F2` | Command runner |
| `Super+W` | Window switcher |
| `Super+X` | Power menu |
| `Super+Ctrl+W` | Wallpaper selector (Rofi) |
| `Alt+Space` | Toggle XKB layout between `us` and `latam` |
| `Super+Shift+B/F/E/Y` | Launch Brave, Thunar, Micro, or Yazi |
| `Print`, `Ctrl+Print`, `Super+Print` | Screenshot (screen, window, area) |
| `Super+1..8` | Focus workspace |
| `Super+Shift+1..8` | Move window to workspace and follow |
| `Super+F`, `Super+Space` | Toggle fullscreen or floating |

Key mappings are defined in [`sxhkdrc`](home/bspwm/.config/bspwm/sxhkdrc).

## Local Machine Overrides

The session works without overrides. If present, they load in order:

1. `~/.config/bspwm/local.env`, before public defaults;
2. `~/.config/bspwm/local.bspwmrc`, after public rules.

Example `local.env`:

```bash
BSPWM_TERMINAL=alacritty
BSPWM_BROWSER=brave
BSPWM_FILE_MANAGER=thunar
BSPWM_EDITOR=micro
BSPWM_TERMINAL_FILE_MANAGER=yazi
BSPWM_XKB_LAYOUTS=us,latam
BSPWM_XKB_OPTIONS=grp:alt_space_toggle
BSPWM_BORDER_WIDTH=0

# Optional session toggles.
BSPWM_PICOM_BACKEND=glx
BSPWM_DISABLE_XKB=0
BSPWM_DISABLE_XCAPE=0
BSPWM_DISABLE_PICOM=0
BSPWM_DISABLE_POLYBAR=0
BSPWM_DISABLE_DUNST=0
BSPWM_DISABLE_POLKIT=0
BSPWM_DISABLE_PLAYERCTLD=0
BSPWM_RESTORE_WALLPAPER=1
```

## Unlinking Symlinks

`unlink` removes only managed symlinks without deleting packages or user data:

```bash
./bin/bspwm unlink --profile desktop
./bin/bspwm unlink --profile desktop --apply
```

## Local Validation

```bash
bash -n bin/bspwm tests/*.sh home/bspwm/.config/bspwm/bspwmrc \
  home/bspwm/.config/bspwm/scripts/*
shellcheck -x bin/bspwm tests/*.sh tests/fakes/session-command \
  home/bspwm/.config/bspwm/bspwmrc home/bspwm/.config/bspwm/scripts/*
./tests/bootstrap-smoke.sh
./tests/session-smoke.sh
git diff --check
```

Legacy component audit is available in [`docs/archcraft-audit.md`](docs/archcraft-audit.md).

## License

Original configuration was based on Archcraft and retains attribution. This repository
is distributed under GPL-3.0; see [`LICENSE`](LICENSE) and
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
