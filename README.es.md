# BSPWM Dotfiles

*Read this in other languages:* [English](README.md)

Sesión de escritorio X11 autónoma, pública y minimalista basada en **BSPWM** (Binary Space Partitioning Window Manager) con el tema Catppuccin Mocha. Funciona de manera 100% independiente o compuesta con el ecosistema principal de dotfiles modulares.

<p align="center">
  <img src="assets/screenshot.webp" alt="Vista previa de BSPWM Desktop" width="100%">
</p>

> [!NOTE]
> **Trabajo en progreso:** Este repositorio ofrece una experiencia de escritorio X11 independiente y se integra con los dotfiles base en [anthonyportugal/dotfiles](https://github.com/anthonyportugal/dotfiles) (rama `refactor/modular-dotfiles`).

---

## 🧱 Arquitectura Modular

La configuración de BSPWM está estructurada en perfiles acumulativos administrados mediante [GNU Stow](https://www.gnu.org/software/stow/):

```text
┌────────────────────────────────────────────────────────────────────────┐
│                       BSPWM DESKTOP ECOSYSTEM (X11)                    │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                    DESKTOP PROFILE (UX & Tools)                  │  │
│  │  • Barra de Estado: Polybar (Catppuccin Pink, Detección Dinámica)│  │
│  │  • Menú de Aplicaciones y Apagado: Rofi                          │  │
│  │  • Notificaciones: Dunst                                         │  │
│  │  • Compositor y Sombras: Picom (GLX / XRender)                   │  │
│  │  • Fondo de Pantalla y Multimedia: Feh, Playerctl, MPV-MPRIS     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      CORE PROFILE (Minimal X11)                  │  │
│  │  • Gestor de Ventanas: BSPWM (Binary Space Partitioning)         │  │
│  │  • Daemon de Atajos: SXHKD                                       │  │
│  │  • Auth X11 y Disposición de Teclado: Xauth, Setxkbmap (US/Latam)│  │
│  │  • Terminal: Alacritty (Tema Catppuccin)                         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Componentes Aprobados

| Capacidad | Selección | Descripción |
| :--- | :--- | :--- |
| **Gestor de Ventanas** | `bspwm` | Gestor de ventanas tipo tiling de particionado binario |
| **Daemon de Atajos** | `sxhkd` | Daemon simple de atajos de teclado para X |
| **Barra de Estado** | `polybar` | Barra moderna con detección dinámica de red y batería |
| **Lanzador de Apps** | `rofi` | Menú de aplicaciones y apagado del sistema |
| **Compositor** | `picom` | Sombras, esquinas redondeadas y opacidad |
| **Notificaciones** | `dunst` | Servidor de notificaciones ligero |
| **Fondo de Pantalla** | `feh` | Gestor de fondos con selector interactivo |
| **Audio / Media** | PipeWire & Playerctl | Stack de audio moderno con soporte de control MPRIS |

---

## 🚀 Instalación y Uso Rápido

### 1. Despliegue Standalone (Recomendado)

```bash
mkdir -p "$HOME/.dotfiles/wm"
git clone https://github.com/anthonyportugal/dotfiles-bspwm.git "$HOME/.dotfiles/wm/bspwm"
cd "$HOME/.dotfiles/wm/bspwm"
```

### 2. Desplegar el Entorno

- **Experiencia de Escritorio Completa (Recomendado):**
  ```bash
  ./bin/bspwm bootstrap --profile desktop --apply
  ```
- **Sesión Core Minimalista (Sin barra ni efectos visuales):**
  ```bash
  ./bin/bspwm bootstrap --profile core --apply
  ```

### Opciones Útiles del Asistente
- **Simulación Dry-run:** Omite `--apply` para previsualizar acciones sin modificar el sistema:
  ```bash
  ./bin/bspwm bootstrap --profile desktop
  ```
- **Diagnóstico del sistema:** Verifica el estado y los enlaces del entorno:
  ```bash
  ./bin/bspwm doctor --profile desktop
  ```
- **Desvincular / Limpiar:** Retira los enlaces simbólicos de forma limpia:
  ```bash
  ./bin/bspwm unlink --profile desktop --apply
  ```

---

## 🔗 Integración con Dotfiles Base

Aunque este repositorio funciona de forma **100% independiente**, se integra limpiamente con el ecosistema principal:
- 🌐 **Repositorio Base:** [anthonyportugal/dotfiles](https://github.com/anthonyportugal/dotfiles) *(Rama activa: `refactor/modular-dotfiles`)*
- **Ecosistema Compartido:** Cuando se instala junto al repositorio base, la configuración de Alacritty, alias de Zsh, configuraciones de Neovim y preferencias GTK se comparten entre sesiones X11 y Wayland.

---

## ⌨️ Atajos de Teclado Principales

| Atajo | Acción |
| :--- | :--- |
| `Super + Return` | Abrir terminal Alacritty (Mosaico) |
| `Super + Shift + Return` | Abrir terminal Alacritty flotante |
| `Super + D` | Abrir menú de aplicaciones Rofi |
| `Super + B` | Abrir navegador web predeterminado (Brave) |
| `Super + E` | Abrir gestor de archivos gráfico (Thunar) |
| `Super + L` | Bloquear pantalla de inmediato (slock / i3lock) |
| `Super + X` | Abrir menú de apagado/sesión Rofi |
| `Super + Shift + P` | Abrir selector interactivo de perfiles de energía (Rofi) |
| `Super + Escape` | Reiniciar sesión de BSPWM y recargar SXHKD |
| `Super + Shift + Escape` | Cerrar sesión de BSPWM |
| `Super + T` | Alternar modo de ventana (*Tiled / Monocle*) |
| `Super + N` | Alternar luz nocturna cálida (Redshift) |
| `Super + W` | Seleccionar fondo de pantalla interactivo con Rofi (Feh) |
| `Alt + Space` | Alternar distribución de teclado US / Latinoamérica |
| `Super + ?` / `Super + Shift + ?` | Abrir hoja de atajos interactiva |
| `Print` / `Super + S` | Captura de pantalla completa |
| `Super + Shift + S` | Captura de región interactiva con anotación en Satty |
| `Super + R` / `Super + Shift + R` | Grabación de pantalla completa / región interactiva (FFmpeg) |
| `Super + Alt + R` | Abrir menú de opciones de audio para grabación (Rofi) |
| `Super + C` / `Super + Shift + C` | Cerrar / Forzar cierre de ventana enfocada |

---

## 🧪 Pruebas Automatizadas

Ejecuta la suite de pruebas automáticas para validar sintaxis, enlaces y scripts:

```bash
./tests/bootstrap-smoke.sh
./tests/session-smoke.sh
```

---

## 📄 Licencia

El código y las configuraciones originales se distribuyen bajo la [Licencia MIT](LICENSE).
Las paletas de Catppuccin y avisos de terceros se detallan en `THIRD_PARTY_NOTICES.md`.
