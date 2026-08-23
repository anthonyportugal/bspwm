#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd -P)
DOTFILES="$REPO_ROOT/bin/bspwm"
TEST_ROOT=""

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "$TEST_ROOT" && "$TEST_ROOT" == /tmp/bspwm-bootstrap-smoke.* ]] || return 0
  find "$TEST_ROOT" -mindepth 1 -delete
  find "$TEST_ROOT" -depth -type d -empty -delete
}

trap cleanup EXIT

command -v stow >/dev/null 2>&1 || fail "GNU Stow es necesario para este smoke test"
[[ -x "$DOTFILES" ]] || fail "$DOTFILES no es ejecutable"

TEST_ROOT=$(mktemp -d /tmp/bspwm-bootstrap-smoke.XXXXXX)
TARGET_DIR="$TEST_ROOT/home with spaces"
CONFLICT_DIR="$TEST_ROOT/conflict"
PARENT_CONFLICT_DIR="$TEST_ROOT/parent-conflict"
PARENT_DESTINATION="$TEST_ROOT/parent-destination"
SCOPE_REPO="$TEST_ROOT/scope-repo"
SCOPE_TARGET="$TEST_ROOT/scope-target"
FAKE_BIN="$TEST_ROOT/fake-bin"
mkdir "$TARGET_DIR" "$CONFLICT_DIR" "$PARENT_CONFLICT_DIR" \
  "$PARENT_DESTINATION" "$SCOPE_REPO" "$SCOPE_TARGET" "$FAKE_BIN"

# Dry-run, aplicación, doctor e idempotencia sobre un home desechable.
"$DOTFILES" bootstrap --profile desktop --stow-only --target "$TARGET_DIR"
"$DOTFILES" bootstrap --profile desktop --stow-only --target "$TARGET_DIR" --apply
"$DOTFILES" doctor --profile desktop --stow-only --target "$TARGET_DIR"
"$DOTFILES" bootstrap --profile desktop --stow-only --target "$TARGET_DIR" --apply

# Una colisión debe detenerse antes de modificar el archivo existente.
mkdir -p "$CONFLICT_DIR/.config/bspwm"
touch "$CONFLICT_DIR/.config/bspwm/bspwmrc"
if "$DOTFILES" bootstrap --profile core --stow-only --target "$CONFLICT_DIR" \
    > "$TEST_ROOT/conflict.out" 2>&1; then
  fail "el dry-run aceptó una colisión"
fi
grep -q 'colisión' "$TEST_ROOT/conflict.out" || fail "no se reportó la colisión"
[[ -f "$CONFLICT_DIR/.config/bspwm/bspwmrc" && \
   ! -L "$CONFLICT_DIR/.config/bspwm/bspwmrc" ]] || \
  fail "el preflight modificó el archivo en conflicto"

ln -s "$PARENT_DESTINATION" "$PARENT_CONFLICT_DIR/.config"
if "$DOTFILES" bootstrap --profile core --stow-only \
    --target "$PARENT_CONFLICT_DIR" > "$TEST_ROOT/parent-conflict.out" 2>&1; then
  fail "el dry-run aceptó un directorio padre enlazado fuera del target"
fi
grep -q 'directorio padre es symlink' "$TEST_ROOT/parent-conflict.out" || \
  fail "no se explicó la colisión del directorio padre"

# El paquete bspwm sólo puede administrar .config/bspwm. Una copia desechable
# contaminada debe fallar antes de invocar Stow o inspeccionar el target real.
cp -a "$REPO_ROOT/bin" "$REPO_ROOT/home" "$REPO_ROOT/packages" "$SCOPE_REPO/"
mkdir -p "$SCOPE_REPO/home/bspwm/.config/pulse"
touch "$SCOPE_REPO/home/bspwm/.config/pulse/cookie"
if "$SCOPE_REPO/bin/bspwm" bootstrap --profile core --stow-only \
    --target "$SCOPE_TARGET" > "$TEST_ROOT/scope.out" 2>&1; then
  fail "el bootstrap aceptó contenido fuera del ownership de bspwm"
fi
grep -q 'contenido fuera del ownership de bspwm: .config/pulse' \
  "$TEST_ROOT/scope.out" || fail "no se explicó la contaminación del paquete"
if grep -q 'Simulación nativa de GNU Stow' "$TEST_ROOT/scope.out"; then
  fail "Stow se ejecutó pese a contenido ajeno dentro del paquete"
fi

# Unlink también simula primero y nunca retira paquetes del sistema.
"$DOTFILES" unlink --profile desktop --target "$TARGET_DIR"
"$DOTFILES" unlink --profile desktop --target "$TARGET_DIR" --apply
if "$DOTFILES" doctor --profile desktop --stow-only --target "$TARGET_DIR" \
    > "$TEST_ROOT/doctor-after-unlink.out" 2>&1; then
  fail "doctor debía detectar los enlaces ausentes después de unlink"
fi

# Adaptadores: pacman falso marca todos los paquetes como faltantes sin tocar
# el sistema; los helpers falsos permiten inspeccionar los comandos generados.
ln -s /usr/bin/false "$FAKE_BIN/pacman"
for backend in shelly paru yay; do
  ln -s /usr/bin/true "$FAKE_BIN/$backend"
done

PATH="$FAKE_BIN:/usr/bin" "$DOTFILES" bootstrap \
  --profile desktop --packages-only --platform arch --backend shelly \
  > "$TEST_ROOT/shelly.out"
grep -q 'shelly install standard' "$TEST_ROOT/shelly.out" || \
  fail "falta el comando de repositorio para Shelly"
grep -q 'shelly install aur brave-bin' "$TEST_ROOT/shelly.out" || \
  fail "falta el comando AUR para Shelly"

PATH="$FAKE_BIN:/usr/bin" "$DOTFILES" bootstrap \
  --profile core --packages-only --platform cachyos \
  > "$TEST_ROOT/auto-cachyos.out"
grep -Eq 'Backend:[[:space:]]+shelly' "$TEST_ROOT/auto-cachyos.out" || \
  fail "la detección automática de CachyOS no priorizó Shelly"
grep -Eq 'Paquetes repo:[[:space:]].*xorg-setxkbmap' \
  "$TEST_ROOT/auto-cachyos.out" || \
  fail "el perfil core no declaró xorg-setxkbmap"

for backend in paru yay; do
  PATH="$FAKE_BIN:/usr/bin" "$DOTFILES" bootstrap \
    --profile desktop --packages-only --platform arch --backend "$backend" \
    > "$TEST_ROOT/$backend.out"
  grep -q "$backend -S --needed --repo" "$TEST_ROOT/$backend.out" || \
    fail "$backend no restringió el lote binario a repositorios"
  grep -q "$backend -S --needed --aur brave-bin" "$TEST_ROOT/$backend.out" || \
    fail "$backend no restringió el fallback brave-bin a AUR"
done

if PATH="$FAKE_BIN:/usr/bin" "$DOTFILES" bootstrap \
    --profile desktop --packages-only --platform arch --backend pacman \
    > "$TEST_ROOT/pacman.out" 2>&1; then
  fail "pacman intentó aceptar un paquete AUR faltante"
fi
grep -q 'pacman sólo gestiona repositorios' "$TEST_ROOT/pacman.out" || \
  fail "pacman no explicó su límite de capacidad"

printf 'OK: bootstrap, doctor, unlink y adaptadores validados\n'
