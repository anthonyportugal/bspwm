# bspwm dotfiles

*Read this in other languages:* [English](README.md)

Sesión X11 pública y autónoma basada en bspwm, con Polybar, Rofi, Picom y
Dunst. Puede instalarse sin los dotfiles base, Mango, Archcraft o configuración
privada.

## Instalación rápida

En CachyOS o Arch Linux, clona el repositorio y entra en él:

```bash
git clone https://github.com/anthonyportugal/bspwm.git
cd bspwm
```

CachyOS puede usar Shelly y su paquete binario de Brave. En Arch genérico,
instala primero `paru` o `yay` si quieres que el perfil `desktop` resuelva el
fallback AUR `brave-bin`.

De los tres comandos siguientes, el primero sólo muestra lo que cambiaría.
Revisa el plan antes de aplicarlo:

```bash
./bin/bspwm bootstrap --profile desktop
./bin/bspwm bootstrap --profile desktop --apply
./bin/bspwm doctor --profile desktop
```

Después:

1. cierra la sesión actual;
2. selecciona `bspwm` en Ly u otro display manager;
3. inicia sesión;
4. pulsa `Super` para abrir las aplicaciones o `Super+X` para el menú de
   sesión;
5. usa `Alt+Space` para alternar entre los layouts `us` y `latam`;
6. usa `Super+Ctrl+W` para seleccionar un wallpaper interactivo con Rofi.

No ejecutes el bootstrap completo con `sudo`. El propio backend eleva sólo la
instalación de paquetes; GNU Stow siempre opera como tu usuario.

## Si algo no aparece al iniciar

### Picom en una máquina virtual

El backend predeterminado es `glx`. Algunas GPUs virtuales necesitan `xrender`.
Crea `~/.config/bspwm/local.env` con:

```bash
BSPWM_PICOM_BACKEND=xrender
```

Este ajuste debe permanecer local: el repositorio público no codifica una
excepción para un hipervisor concreto.

### Polybar

Los logs se guardan en `$XDG_STATE_HOME/bspwm/polybar` cuando la variable
existe, o en `~/.local/state/bspwm/polybar` en caso contrario:

```bash
sed -n '1,160p' ~/.local/state/bspwm/polybar/*.log
```

`launcher.log` registra si la selección fue automática o explícita. Los demás
archivos se separan por monitor y contienen la salida de Polybar. Lanzamientos
simultáneos se serializan para evitar que dos procesos terminen o dupliquen la
barra durante el inicio de la sesión.

Polybar detecta red y batería por capacidades. Si esa selección termina durante
el arranque, el launcher reintenta una vez con RAM, almacenamiento y layout XKB
como conjunto mínimo seguro.
Puedes reemplazar la selección automática desde `local.env`:

```bash
BSPWM_POLYBAR_RIGHT='pulseaudio memory filesystem xkeyboard'
```

Una selección explícita tiene precedencia y no se reemplaza automáticamente.
Una variable ausente, vacía o compuesta sólo por espacios selecciona el modo
automático; el valor resuelto se exporta antes de ejecutar Polybar.
En múltiples monitores, la selección derecha se aplica literalmente a cada
barra. El tray no forma parte de ese override: el launcher lo reserva en el
bloque central, a la derecha de fecha/hora, sólo para la primera barra. No
incluyas `tray` en `BSPWM_POLYBAR_RIGHT` salvo que quieras reemplazar
deliberadamente esa composición.

El mensaje `libuv error while polling X connection: bad file descriptor` no
identifica por sí solo un módulo concreto. Comprueba primero si las instancias
actuales siguen activas y revisa las líneas anteriores de cada log, donde el
launcher registra monitor, `modules-center` y `modules-right` utilizados.

### Diagnóstico rápido

```bash
bspc query -M --names
bspc query -D --names
setxkbmap -query
pgrep -a 'sxhkd|xcape|polybar|picom|dunst|playerctld'
./bin/bspwm doctor --profile desktop
```

El perfil instala `xorg-xauth`, necesario para que display managers como Ly
puedan autorizar la sesión X en una instalación mínima.

## Qué instala

Los perfiles son acumulativos:

- `core`: Xorg, Xauth, XKB mediante `setxkbmap`, bspwm, sxhkd, GNU Stow y la
  configuración mínima de sesión;
- `desktop` (predeterminado): añade Polybar, Picom, Rofi, Dunst, `feh`, `xcape`,
  audio, capturas, fuentes y las aplicaciones utilizadas por los atajos públicos.

La detección automática de paquetes intenta Shelly en CachyOS y después
`paru`, `yay` y `pacman`. Puedes inspeccionar un backend o separar paquetes de
dotfiles sin aplicar cambios:

```bash
./bin/bspwm bootstrap --profile desktop --backend paru
./bin/bspwm bootstrap --profile core --packages-only
./bin/bspwm bootstrap --profile desktop --stow-only
```

Los manifests y la procedencia de cada paquete están documentados en
[`packages/README.md`](packages/README.md).

## Qué configura

Este repositorio administra exclusivamente:

- `~/.config/bspwm` y las reglas de bspwm;
- keybindings de sxhkd;
- los layouts XKB de esta sesión X11, sin modificar la configuración global;
- Polybar, Picom, Dunst y Rofi para esta sesión;
- helpers X11 consumidos por esos componentes;
- dependencias, bootstrap y validaciones de su propio alcance.

No administra display manager, drivers o GPU híbrida, secrets, wallpapers ni
configuración privada. El paquete `bspwm` proporciona la entrada de sesión que
Ly puede seleccionar.

La configuración conserva la experiencia Catppuccin del repositorio original,
pero no depende de `/etc/skel`, `/usr/share/archcraft`, fuentes Feather ni
nombres concretos de monitores, interfaces, baterías o backlights.

Alacritty se instala como terminal predeterminado, pero su configuración no se
duplica aquí: al ser una aplicación compartida entre X11 y Wayland, el tema
Catppuccin portable pertenece al perfil `desktop` del repositorio base de
dotfiles. bspwm continúa funcionando con la configuración de Alacritty del
usuario cuando ese repositorio opcional no está presente.

## Comportamiento de la sesión

- ocho workspaces se distribuyen entre los monitores detectados;
- Polybar se lanza una vez por monitor;
- Polybar ocupa todo el ancho sin margen ni radio exterior; muestra
  launcher/workspaces, fecha y hora, volumen, RAM usada, almacenamiento raíz
  usado y layout, y añade red y batería cuando existen;
- el workspace activo conserva su icono y lo resalta con Catppuccin Pink; el
  tray usa el renderizado nativo, junto a fecha/hora sólo en el primer monitor;
- audio usa PipeWire/WirePlumber mediante `wpctl`;
- mpv expone MPRIS mediante `mpv-mpris` y se controla con Playerctl;
- screenshots se guardan en el directorio XDG `Pictures/Screenshots` y se
  copian con Xclip cuando está disponible;
- el power menu de Rofi usa una cuadrícula e iconos de Nerd Font;
- el power menu sólo se abre mediante `Super+X`; no ocupa espacio en Polybar;
- selector de wallpapers con `Super+Ctrl+W` escaneando `~/Pictures/Wallpapers`;
- Picom aplica esquinas redondeadas y atenúa levemente las ventanas inactivas
  para indicar foco sin un borde rectangular; el backend y el borde tradicional
  pueden reemplazarse localmente;
- ningún cambio de tema o detección de hardware reescribe el checkout.

### Atajos principales

| Atajo | Acción |
| --- | --- |
| `Super` | Aplicaciones con Rofi |
| `Super+Enter` | Terminal |
| `Super+Shift+Enter` | Terminal flotante |
| `Super+D` / `Alt+F1` | Aplicaciones con Rofi |
| `Alt+F2` | Runner |
| `Super+W` | Selector de ventanas |
| `Super+X` | Menú de sesión |
| `Super+Ctrl+W` | Selector de wallpaper con Rofi |
| `Alt+Space` | Alternar layout XKB entre `us` y `latam` |
| `Super+Shift+B/F/E/Y` | Brave, Thunar, Micro o Yazi |
| `Print`, `Ctrl+Print`, `Super+Print` | Pantalla, ventana o área |
| `Super+1..8` | Cambiar de workspace |
| `Super+Shift+1..8` | Mover ventana y seguirla |
| `Super+F`, `Super+Space` | Fullscreen o floating |

El mapa de sxhkd está en [`sxhkdrc`](home/bspwm/.config/bspwm/sxhkdrc).
`Alt+Space` usa el selector de grupo nativo de XKB y por eso no aparece como
binding de sxhkd.

## Configuración local

La instalación funciona sin overrides. Si existen, se cargan en este orden:

1. `~/.config/bspwm/local.env`, antes de los defaults públicos;
2. `~/.config/bspwm/local.bspwmrc`, después de las reglas públicas.

Ejemplo de `local.env`:

```bash
BSPWM_TERMINAL=alacritty
BSPWM_BROWSER=brave
BSPWM_FILE_MANAGER=thunar
BSPWM_EDITOR=micro
BSPWM_TERMINAL_FILE_MANAGER=yazi
BSPWM_XKB_LAYOUTS=us,latam
BSPWM_XKB_OPTIONS=grp:alt_space_toggle
BSPWM_BORDER_WIDTH=0

# Ajustes opcionales de sesión.
BSPWM_PICOM_BACKEND=glx
BSPWM_DISABLE_XKB=0
BSPWM_DISABLE_XCAPE=0
BSPWM_DISABLE_PICOM=0
BSPWM_DISABLE_POLYBAR=0
BSPWM_DISABLE_DUNST=0
BSPWM_DISABLE_POLKIT=0
BSPWM_DISABLE_PLAYERCTLD=0
BSPWM_RESTORE_WALLPAPER=1

# BSPWM_XCAPE_MAPPING='Super_L=Alt_L|F1;Super_R=Alt_L|F1'
# BSPWM_POLYBAR_RIGHT='pulseaudio memory filesystem xkeyboard'
# BSPWM_MONITOR_ORDER='...'
# BSPWM_WORKSPACES='1 2 3 4 5 6 7 8'
# BSPWM_LOCK_COMMAND='...'
# BSPWM_WALLPAPER_COMMAND='...'
```

Ambos archivos son ajenos al repositorio y pueden ser archivos regulares dentro
de `~/.config/bspwm`: Stow enlaza cada archivo público con `--no-folding`. No
deben contener secretos.

## Desinstalar los enlaces

`unlink` no elimina paquetes ni archivos ajenos. Primero simula y sólo modifica
con `--apply`:

```bash
./bin/bspwm unlink --profile desktop
./bin/bspwm unlink --profile desktop --apply
```

## Detalles de seguridad y mantenimiento

El bootstrap es dry-run por defecto, comprueba colisiones, ejecuta la simulación
nativa de Stow, usa `--no-folding` y nunca ejecuta `--adopt`. Actualizar el
sistema sigue siendo un paso separado y deliberado del usuario.

El paquete Stow `home/bspwm` sólo puede contener rutas bajo `.config/bspwm`.
El preflight rechaza cualquier contenido ajeno antes de invocar Stow. Durante
pruebas de aplicaciones reales, usa siempre un home temporal: no asignes
`home/bspwm` directamente a `$HOME`, porque las aplicaciones podrían escribir
cookies, caches o estado generado dentro del source tree.

Validaciones locales que no instalan paquetes ni modifican el home real:

```bash
bash -n bin/bspwm tests/*.sh home/bspwm/.config/bspwm/bspwmrc \
  home/bspwm/.config/bspwm/scripts/*
shellcheck -x bin/bspwm tests/*.sh tests/fakes/session-command \
  home/bspwm/.config/bspwm/bspwmrc home/bspwm/.config/bspwm/scripts/*
./tests/bootstrap-smoke.sh
./tests/session-smoke.sh
git diff --check
```

El inventario y la disposición de componentes heredados están en
[`docs/archcraft-audit.md`](docs/archcraft-audit.md).

## Origen y licencia

La configuración original se basó en Archcraft y conserva su atribución. Este
repositorio se distribuye bajo GPL-3.0; consulta [`LICENSE`](LICENSE) y
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
