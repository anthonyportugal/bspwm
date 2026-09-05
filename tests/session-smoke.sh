#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
CONFIG_ROOT="$REPO_ROOT/home/bspwm/.config/bspwm"
FAKE_SOURCE="$SCRIPT_DIR/fakes/session-command"
TEST_ROOT=""

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "$TEST_ROOT" && "$TEST_ROOT" == /tmp/bspwm-session-smoke.* ]] || return 0
  if [[ -r "${POLYBAR_PIDS:-}" ]]; then
    while IFS= read -r polybar_pid; do
      [[ "$polybar_pid" =~ ^[0-9]+$ ]] || continue
      kill -TERM "$polybar_pid" 2>/dev/null || true
    done < "$POLYBAR_PIDS"
  fi
  find "$TEST_ROOT" -mindepth 1 -delete
  rmdir "$TEST_ROOT"
}

trap cleanup EXIT

[[ -x "$FAKE_SOURCE" ]] || fail "$FAKE_SOURCE no es ejecutable"
TEST_ROOT=$(mktemp -d /tmp/bspwm-session-smoke.XXXXXX)
FAKE_BIN="$TEST_ROOT/bin"
TEST_LOG="$TEST_ROOT/commands.log"
POLYBAR_PIDS="$TEST_ROOT/polybar-pids"
mkdir "$FAKE_BIN"
touch "$TEST_LOG"
touch "$POLYBAR_PIDS"

fake_commands=(
  alacritty
  bluetoothctl
  brave
  bspc
  ffmpeg
  i3lock
  notify-send
  pactl
  pgrep
  pkill
  playerctl
  playerctld
  polybar
  polybar-msg
  slop
  sxhkd
  setxkbmap
  systemctl
  systemd-run
  xcape
  xdotool
  xsetroot
)
for command_name in "${fake_commands[@]}"; do
  ln -s "$FAKE_SOURCE" "$FAKE_BIN/$command_name"
done

export BSPWM_TEST_LOG="$TEST_LOG"
export BSPWM_TEST_MONITORS='MONITOR_A MONITOR_B'
export BSPWM_TEST_POLYBAR_PIDS="$POLYBAR_PIDS"
export PATH="$FAKE_BIN:/usr/bin"
export XDG_CONFIG_HOME="$REPO_ROOT/home/bspwm/.config"
export XDG_STATE_HOME="$TEST_ROOT/state"
export XDG_RUNTIME_DIR="$TEST_ROOT/runtime"
mkdir -p "$XDG_STATE_HOME" "$XDG_RUNTIME_DIR"
export BSPWM_DISABLE_DUNST=1
export BSPWM_DISABLE_PICOM=1
export BSPWM_DISABLE_POLYBAR=1
export BSPWM_DISABLE_POLKIT=1
export BSPWM_DISABLE_PLAYERCTLD=1
export BSPWM_RESTORE_WALLPAPER=0

"$CONFIG_ROOT/bspwmrc"

if [[ $(grep -c '^bspc monitor ' "$TEST_LOG") -ne 2 ]]; then
  fail "los workspaces no se distribuyeron entre dos monitores"
fi
if ! grep -q '^bspc wm --reorder-monitors MONITOR_A MONITOR_B$' "$TEST_LOG"; then
  fail "no se preservó el orden dinámico de monitores"
fi
if grep -Eq 'DP-[0-9]|HDMI-[0-9]' "$TEST_LOG"; then
  fail "la sesión usó un nombre de monitor fijo"
fi
if ! grep -q '^setxkbmap -layout us,latam -option grp:alt_space_toggle$' "$TEST_LOG"; then
  fail "la sesión no configuró el selector XKB us/latam"
fi
for _ in {1..20}; do
  grep -Fq 'xcape -e Super_L=Alt_L|F1;Super_R=Alt_L|F1' "$TEST_LOG" && break
  sleep 0.01
done
if ! grep -Fq 'xcape -e Super_L=Alt_L|F1;Super_R=Alt_L|F1' "$TEST_LOG"; then
  fail "Super aislada no se mapeó mediante xcape"
fi

"$CONFIG_ROOT/scripts/bspwm-terminal" --float -- micro
if ! grep -q '^alacritty --class bspwm-float,bspwm-float -e micro$' "$TEST_LOG"; then
  fail "el terminal flotante no recibió una clase portable"
fi

"$CONFIG_ROOT/scripts/bspwm-launch" browser
grep -q '^brave$' "$TEST_LOG" || fail "el launcher no utilizó Brave"

BSPWM_TEST_I3LOCK_COLOR=1 "$CONFIG_ROOT/scripts/bspwm-lock"
grep -q '^i3lock --color=1e1e2eff --clock --indicator.*--keylayout 2' "$TEST_LOG" || \
  fail "bspwm-lock no invocó i3lock-color con la paleta Catppuccin y keylayout nativo"

BSPWM_TEST_I3LOCK_COLOR=0 "$CONFIG_ROOT/scripts/bspwm-lock"
grep -q '^i3lock -c 1e1e2e -n$' "$TEST_LOG" || \
  fail "bspwm-lock no degradó limpiamente a i3lock estándar"

media_output=$("$CONFIG_ROOT/scripts/polybar-media")
[[ "$media_output" == *"Artist — Track"* ]] || fail "el módulo multimedia no leyó Playerctl"

bluetooth_output=$("$CONFIG_ROOT/scripts/polybar-bluetooth")
[[ "$bluetooth_output" == *Headphones* ]] || fail "el módulo Bluetooth no mostró el dispositivo conectado"

POLYBAR_THEME="$CONFIG_ROOT/themes/catppuccin/polybar"
for geometry_setting in 'width = 100%' 'offset-x = 0' 'offset-y = 0' 'radius = 0'; do
  grep -Fxq "$geometry_setting" "$POLYBAR_THEME/config.ini" ||
    fail "Polybar no conservó la geometría anclada: $geometry_setting"
done
grep -Fxq "modules-center = \${env:BSPWM_POLYBAR_CENTER:bspwm tray}" \
  "$POLYBAR_THEME/config.ini" || fail "el tray no quedó en el bloque central"
grep -Fxq 'ACCENT = #F5C2E7' "$POLYBAR_THEME/colors.ini" ||
  fail "Polybar no usa Catppuccin Pink como acento"
grep -Fxq 'label-focused = %name%' "$POLYBAR_THEME/modules.ini" ||
  fail "el workspace activo no conserva su nombre/icono real"
grep -Fxq "label-focused-foreground = \${color.ACCENT}" \
  "$POLYBAR_THEME/modules.ini" || fail "el workspace activo no usa el acento común"
if grep -q '^ws-icon-' "$POLYBAR_THEME/modules.ini"; then
  fail "Polybar volvió a sustituir los nombres reales de los workspaces"
fi
tray_section=$(awk '
  /^\[module\/tray\]$/ { in_tray = 1; next }
  /^\[module\// && in_tray { exit }
  in_tray { print }
' "$POLYBAR_THEME/modules.ini")
grep -Fxq 'format-margin = 4px' <<< "$tray_section" ||
  fail "el tray perdió su margen nativo"
grep -Fxq 'tray-size = 65%' <<< "$tray_section" ||
  fail "el tray perdió su tamaño controlado"
if grep -Eq '^format-(background|padding|prefix|suffix)' <<< "$tray_section"; then
  fail "el tray volvió a introducir fondos o tapas decorativas"
fi

export BSPWM_TEST_POLYBAR_FAIL_AUTO=1
export BSPWM_TEST_MONITOR_DELAY=0.2
unset BSPWM_POLYBAR_RIGHT
"$CONFIG_ROOT/scripts/launch-polybar" &
auto_launcher_pid=$!
sleep 0.05
"$CONFIG_ROOT/scripts/launch-polybar"
wait "$auto_launcher_pid"
unset BSPWM_TEST_MONITOR_DELAY

if [[ $(grep -c 'se ignoró un launcher concurrente' \
    "$XDG_STATE_HOME/bspwm/polybar/launcher.log") -ne 1 ]]; then
  fail "los lanzamientos concurrentes de Polybar no se serializaron"
fi

initial_polybar_lines=$(grep '^polybar monitor=.* center=.* modules=' "$TEST_LOG" |
  grep -v ' modules=memory xkeyboard$' || true)
if [[ $(grep -c ' center=bspwm tray ' <<< "$initial_polybar_lines") -ne 1 ]]; then
  fail "el tray no quedó junto a los workspaces en una única barra"
fi
if ! grep -q ' modules=pulseaudio memory' <<< "$initial_polybar_lines"; then
  fail "Polybar no incluyó RAM en la selección automática"
fi
if grep -q ' modules=.*tray' <<< "$initial_polybar_lines"; then
  fail "el tray permaneció mezclado con las métricas derechas"
fi
if ! grep -q ' power$' <<< "$initial_polybar_lines"; then
  fail "Polybar no incluyó el botón power al final de la selección automática"
fi
fallback_polybar_lines=$(grep \
  '^polybar monitor=.* center=.* modules=memory xkeyboard$' \
  "$TEST_LOG" || true)
if [[ $(grep -c '^polybar ' <<< "$fallback_polybar_lines") -ne 2 ]]; then
  fail "Polybar no aplicó el fallback seguro por monitor"
fi
if [[ $(grep -c ' center=bspwm tray ' <<< "$fallback_polybar_lines") -ne 1 ]]; then
  fail "el fallback no conservó el tray sólo en la primera barra"
fi

auto_attempts_before=$(grep -c '^polybar monitor=.* center=.* modules=' "$TEST_LOG")
safe_fallbacks_before=$(grep -c \
  '^polybar monitor=.* center=.* modules=memory xkeyboard$' "$TEST_LOG")
export BSPWM_POLYBAR_RIGHT='   '
"$CONFIG_ROOT/scripts/launch-polybar"
auto_attempts_after=$(grep -c '^polybar monitor=.* center=.* modules=' "$TEST_LOG")
safe_fallbacks_after=$(grep -c \
  '^polybar monitor=.* center=.* modules=memory xkeyboard$' "$TEST_LOG")
if [[ "$auto_attempts_after" -ne $(( auto_attempts_before + 4 )) ]] ||
   [[ "$safe_fallbacks_after" -ne $(( safe_fallbacks_before + 2 )) ]]; then
  fail "un BSPWM_POLYBAR_RIGHT en blanco no activó la selección automática"
fi

safe_fallbacks_before=$safe_fallbacks_after
export BSPWM_POLYBAR_RIGHT=date
if "$CONFIG_ROOT/scripts/launch-polybar"; then
  fail "Polybar ocultó el fallo de un override explícito"
fi
safe_fallbacks_after=$(grep -c \
  '^polybar monitor=.* center=.* modules=memory xkeyboard$' "$TEST_LOG")
if [[ "$safe_fallbacks_after" -ne "$safe_fallbacks_before" ]]; then
  fail "Polybar reemplazó silenciosamente los módulos explícitos"
fi

# bspwm-recording: estado inicial
rec_status=$("$CONFIG_ROOT/scripts/bspwm-recording" status)
[[ "$rec_status" == "stopped" ]] || fail "bspwm-recording debería reportar stopped inicialmente"
rec_polybar=$("$CONFIG_ROOT/scripts/bspwm-recording" polybar)
[[ -z "$rec_polybar" ]] || fail "bspwm-recording polybar debería estar vacío inicialmente"

# bspwm-recording: inicio fullscreen y notificación polybar
"$CONFIG_ROOT/scripts/bspwm-recording" start fullscreen none
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "recording" ]] || \
  fail "bspwm-recording no pasó a estado recording"
rec_polybar=$("$CONFIG_ROOT/scripts/bspwm-recording" polybar)
[[ "$rec_polybar" == *"REC"* ]] || fail "bspwm-recording polybar no mostró indicador REC"
if ! grep -q 'systemd-run.*bspwm-recording.service.*ffmpeg.*-f x11grab' "$TEST_LOG"; then
  fail "bspwm-recording no lanzó ffmpeg para captura x11grab"
fi
if ! grep -q '^polybar-msg action #recording.hook.0$' "$TEST_LOG"; then
  fail "bspwm-recording no notificó a polybar vía IPC al iniciar"
fi

# bspwm-recording: detención
"$CONFIG_ROOT/scripts/bspwm-recording" stop
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "stopped" ]] || \
  fail "bspwm-recording no se detuvo correctamente"
rec_polybar=$("$CONFIG_ROOT/scripts/bspwm-recording" polybar)
[[ -z "$rec_polybar" ]] || fail "bspwm-recording polybar no se limpió al detener"

# bspwm-recording: región interactiva
"$CONFIG_ROOT/scripts/bspwm-recording" start region none
if ! grep -q 'systemd-run.*bspwm-recording.service.*ffmpeg.*-video_size 800x600' "$TEST_LOG" ||
   ! grep -Fq '+100,200' "$TEST_LOG"; then
  fail "bspwm-recording no invocó ffmpeg con la geometría de slop"
fi
"$CONFIG_ROOT/scripts/bspwm-recording" stop

# bspwm-recording: audio con micrófono
"$CONFIG_ROOT/scripts/bspwm-recording" start fullscreen mic
if ! grep -q 'systemd-run.*bspwm-recording.service.*ffmpeg.*-f pulse -i default' "$TEST_LOG"; then
  fail "bspwm-recording no configuró la captura de micrófono"
fi
"$CONFIG_ROOT/scripts/bspwm-recording" stop

# bspwm-recording: audio de escritorio
"$CONFIG_ROOT/scripts/bspwm-recording" start fullscreen desktop
if ! grep -q 'systemd-run.*bspwm-recording.service.*ffmpeg.*-f pulse -i alsa_output.pci.test-sink.monitor' "$TEST_LOG"; then
  fail "bspwm-recording no configuró el monitor de audio de escritorio"
fi
"$CONFIG_ROOT/scripts/bspwm-recording" stop

# bspwm-recording: audio mixto (micrófono + escritorio) y limpieza de módulos
"$CONFIG_ROOT/scripts/bspwm-recording" start fullscreen both
if ! grep -q 'systemd-run.*bspwm-recording.service.*ffmpeg.*-f pulse -i bspwm_rec_mix.monitor' "$TEST_LOG"; then
  fail "bspwm-recording no configuró el sink mixto para audio dual"
fi
if ! grep -q 'pactl load-module module-null-sink sink_name=bspwm_rec_mix' "$TEST_LOG"; then
  fail "bspwm-recording no creó el sink nulo para mezclar audio"
fi
"$CONFIG_ROOT/scripts/bspwm-recording" stop
if ! grep -q 'pactl unload-module 42' "$TEST_LOG"; then
  fail "bspwm-recording no descargó los módulos de audio al detener"
fi

# bspwm-recording: alternancia cruzada entre atajos (cualquiera detiene grabación en curso)
"$CONFIG_ROOT/scripts/bspwm-recording" toggle
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "recording" ]] || \
  fail "toggle no inició grabación"
"$CONFIG_ROOT/scripts/bspwm-recording" toggle-region
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "stopped" ]] || \
  fail "toggle-region no detuvo la grabación fullscreen activa"

"$CONFIG_ROOT/scripts/bspwm-recording" toggle-region
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "recording" ]] || \
  fail "toggle-region no inició grabación de región"
"$CONFIG_ROOT/scripts/bspwm-recording" toggle
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "stopped" ]] || \
  fail "toggle no detuvo la grabación de región activa"

"$CONFIG_ROOT/scripts/bspwm-recording" toggle
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "recording" ]] || \
  fail "toggle no inició grabación"
"$CONFIG_ROOT/scripts/bspwm-recording" menu
[[ $("$CONFIG_ROOT/scripts/bspwm-recording" status) == "stopped" ]] || \
  fail "menu no detuvo la grabación activa"

printf 'OK: sesión dinámica y helpers principales validados\n'
