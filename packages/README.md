# Manifiestos de bspwm

Estos archivos son datos de entrada para `bin/bspwm`; no son scripts. Usan un
nombre por línea, omiten líneas vacías/comentarios y no fijan versiones de una
distribución rolling.

## Perfiles

Los perfiles son acumulativos:

| Perfil | Contenido |
| --- | --- |
| `core` | Xorg, Xauth, bspwm, sxhkd, GNU Stow y utilidades requeridas por la sesión mínima. |
| `desktop` | `core` más Polybar, Picom, Rofi, Dunst, `xcape`, audio, capturas, fuentes y aplicaciones usadas por los atajos públicos. |

Ambos seleccionan el único paquete Stow `bspwm`. El perfil predeterminado es
`desktop`.

## Procedencia

La resolución respeta este orden:

1. repositorios disponibles para CachyOS;
2. repositorios oficiales de Arch;
3. AUR sólo cuando no existe un paquete binario apropiado.

Los nombres de `repo/` se comprobaron primero en el portal de paquetes de
CachyOS el 2026-08-21. Son paquetes binarios disponibles mediante los
repositorios que CachyOS configura, incluidos sus mirrors de Arch. Brave es la
única excepción con manifests separados: `brave-bin` procede del repositorio
`cachyos` y queda como fallback AUR en Arch genérico.

`xorg-xauth` forma parte de `core` porque la primera prueba desde una instalación
mínima mostró que Ly lo necesita para autorizar la sesión X.
`xorg-setxkbmap` aplica los layouts portables de la sesión y su selector de
grupo, sin modificar la política global del sistema. `xcape` pertenece a
`desktop` y permite abrir Rofi al pulsar y soltar Super sin interferir con los
atajos que mantienen Super presionada. `util-linux` proporciona `flock`, usado
para impedir lanzamientos concurrentes de Polybar durante el arranque.
`i3lock-color` (AUR) proporciona el bloqueador con reloj, fecha y anillo
Catppuccin en paridad completa con MangoWM; se declara en `packages/aur/desktop.txt`.
`ffmpeg` y `slop` proporcionan la grabación de pantalla completa y por región
en paridad funcional con Wayland.

`external/` documenta fuentes que requerirían otro adaptador; actualmente no
selecciona ninguna.

## Backends

La detección automática intenta Shelly sólo en CachyOS y continúa con `paru`,
`yay` y `pacman`. Shelly, paru y yay pueden resolver el fallback AUR.
`pacman` se limita a paquetes binarios y el preflight se detiene si falta un
paquete AUR.

Los manifests son autónomos. Pueden repetir aplicaciones también declaradas en
los dotfiles base; el package manager deduplica la instalación y este
repositorio no consulta manifests externos.
