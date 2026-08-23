# Audit de autonomía frente a Archcraft

Fecha del contraste: 2026-08-21.

## Baseline y referencia

- baseline público de este repositorio: `4062ad0`;
- paquete usado como referencia local: `archcraft-bspwm 7.0-6`;
- fuente implícita del sistema: `/etc/skel/.config/bspwm`;
- licencia declarada por el paquete de referencia: GPL3.

El baseline contenía `bspwmrc`, `sxhkdrc`, `picom.conf` y un tema
Catppuccin parcial. No contenía el directorio `scripts/`, `dunstrc`,
`xsettingsd`, las configuraciones de terminal ni varios archivos globales de
themes que esos mismos archivos intentaban ejecutar o modificar.

El paquete de Archcraft aportaba 25 helpers y diez temas completos. Por ello el
repositorio sólo funcionaba en una máquina donde Archcraft ya hubiese poblado
el home desde `/etc/skel`.

## Acoplamientos encontrados

| Área | Estado original | Problema |
| --- | --- | --- |
| Monitores | `DP-0`, `HDMI-0`, `HDMI-1` | Fallaba al cambiar outputs o usar laptop/VM. |
| Polybar | `system.ini` con ACAD, BAT1, amdgpu_bl1 y enp3s0 | Hardware de una máquina convertido en source público. |
| Autostart | `killall -9` incluido `bspc` | Terminación agresiva y ownership ambiguo. |
| Polkit | `/usr/lib/xfce-polkit/xfce-polkit` | Dependencia de un proveedor no declarado. |
| Temas | `apply.sh` hacía numerosos `sed -i` | Cambiaba archivos versionados y configs ajenas al repo. |
| Runtime | marcador `.module` dentro de Polybar | La detección escribía estado en el checkout. |
| Assets | iconos y fuente bajo `/usr/share/archcraft` | El repositorio no poseía lo que mostraba. |
| Keybindings | casi todos llamaban helpers ausentes | Checkout público incompleto. |
| Apps | MPD, Spotify, Geany, Ranger, Vim y Viewnior | Stack heredado distinto del acordado. |
| Sesión | xsettingsd, ksuperkey, xfce4-power-manager y layout fijo | Dependencias/decisiones del sistema no documentadas. |

## Disposición aprobada

| Función heredada | Resultado en P7 |
| --- | --- |
| Workspaces y reglas bspwm | Conservados y simplificados; distribución dinámica por monitores. |
| Keybindings de gestión de ventanas | Conservados con comandos explícitos de bspwm. |
| Polybar Catppuccin | Conservada, estática y lanzada por monitor; barra anclada sin margen/radio exterior y módulos compactos inspirados visualmente en `tsjazil/dotfiles`, sin copiar hardcodes o scripts. |
| Red/batería/backlight/Bluetooth | Red y batería se detectan para la barra; brillo permanece en atajos y los módulos extra siguen disponibles mediante override explícito. |
| Picom | Conservado con backend localmente reemplazable, radio moderado y atenuación de ventanas inactivas como indicador de foco. |
| Dunst | Config propia sin iconos Archcraft. |
| Rofi | Launcher estático y power menu en cuadrícula con Nerd Font; sin fuente Feather de Archcraft. |
| Super aislada | `ksuperkey` sustituido por `xcape`, paquete binario genérico. |
| Layout XKB de sesión | Default portable `us,latam` con `Alt+Space`, reemplazable o desactivable localmente. |
| Terminal | Alacritty por defecto, reemplazable por nombre de comando; su tema compartido pertenece al repositorio base. |
| Brave/Thunar/Micro/Yazi | Integrados mediante defaults reemplazables. |
| MPD/ncmpcpp/Spotify | Retirados; multimedia genérica con mpv/Playerctl. |
| Screenshots | Reimplementados con maim/Xclip, sin visor de imágenes obligatorio. |
| Volumen | Reimplementado con `wpctl`, sin Pulsemixer. |
| Brillo | Reimplementado con `brightnessctl`, sin nombre de backlight. |
| Theme switcher y `apply.sh` | Retirados; no se muta source para cambiar apariencia. |
| asroot/colorpicker/networkmanager-dmenu | Retirados del baseline público. |
| Wallpaper | Hook opcional; ningún asset o repo privado es requerido. |
| Modelo físico/política global de teclado, GPU y display manager | Retirados del ownership de estos dotfiles. |

## Ownership resultante

`home/bspwm/.config/bspwm` contiene todos los archivos requeridos por la
sesión. Los dos únicos puntos externos intencionales son:

- paquetes declarados en `packages/`;
- archivos opcionales `local.env` y `local.bspwmrc` creados fuera del
  checkout.

Los logs se escriben bajo XDG state. La ausencia de wallpapers u overrides no
es un error. El bootstrap valida además que el paquete Stow no contenga rutas
fuera de `.config/bspwm`, evitando que estado generado por una aplicación se
convierta accidentalmente en configuración pública.

## Condiciones para considerar eliminado el acoplamiento

- ningún archivo de sesión referencia `/etc/skel` o
  `/usr/share/archcraft`;
- no aparecen nombres conocidos de outputs, batería, adaptador, backlight o
  interfaz del sistema de referencia;
- Bash, Polybar y Rofi pueden analizar las fuentes sin una sesión Archcraft;
- Stow completa dry-run/apply/doctor/unlink sobre un home temporal;
- los planes de paquetes funcionan con backends falsos y no instalan nada en
  el host durante tests;
- la sesión arranca visualmente en la VM del usuario.

La primera prueba en VM confirmó el arranque standalone después de declarar
`xorg-xauth`. Una segunda prueba confirmó Rofi y aisló una diferencia entre la
selección automática y explícita de Polybar, aunque ambas cargaban los mismos
módulos. El launcher ahora normaliza/exporta el valor resuelto, limita la sonda
de BlueZ y serializa arranques concurrentes. La comprobación final en VM confirmó
que la barra aparece mediante selección automática sin configurar
`BSPWM_POLYBAR_RIGHT`; con ello queda satisfecha la validación visual de P7.
Una revisión visual posterior amplió el pulido de Polybar y Picom tomando
`tsjazil/dotfiles` como referencia de apariencia. La implementación conserva la
detección portable y traslada la configuración compartida de Alacritty al repo
base. El último ajuste fija Pink como acento, sitúa el tray junto a fecha/hora y
mantiene la barra anclada. La prueba con los nombres por glifo y `volumeicon`
descartó los adornos circulares: el workspace activo conserva ahora su icono
real coloreado y el tray usa su renderizado nativo. Requiere una nueva
comprobación en VM antes de volver a cerrar la fase.
