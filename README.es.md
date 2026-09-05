# BSPWM Dotfiles

*Read this in other languages:* [English](README.md)

Sesión de escritorio X11 autónoma, pública y minimalista basada en **BSPWM** (Binary Space Partitioning Window Manager) con el tema Catppuccin Mocha. Funciona de manera 100% independiente o compuesta con el ecosistema principal de dotfiles modulares.

<p align="center">
  <img src="assets/screenshot.webp" alt="Vista previa de BSPWM Desktop" width="100%">
</p>

> [!NOTE]
> **Trabajo en progreso:** Este repositorio se encuentra en desarrollo y mantenimiento activo. Ofrece una experiencia de escritorio X11 independiente y se integra con los dotfiles base en [anthonyportugal/dotfiles](https://github.com/anthonyportugal/dotfiles) (rama `refactor/modular-dotfiles`). *(Nota: Este repositorio pasará a llamarse `dotfiles-bspwm` al finalizar la migración).*

---

## 🧱 Arquitectura Modular

La configuración de BSPWM está estructurada en perfiles acumulativos administrados mediante [GNU Stow](https://www.gnu.org/software/stow/):

```text
┌────────────────────────────────────────────────────────────────────────┐
│                       ECOSISTEMA BSPWM DESKTOP (X11)                   │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                   PERFIL DESKTOP (Visual & UX)                   │  │
│  │  • Barra de estado: Polybar (Catppuccin Pink, Módulos Dinámicos) │  │
│  │  • Lanzador de apps y menú de energía: Rofi                      │  │
│  │  • Notificaciones de escritorio: Dunst                           │  │
│  │  • Compositor y sombras: Picom (GLX / XRender)                   │  │
│  │  • Fondos y multimedia: Feh, Playerctl, MPV-MPRIS                │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     PERFIL CORE (Base Minimal X11)               │  │
│  │  • Administrador de ventanas: BSPWM                              │  │
│  │  • Demonio de atajos de teclado: SXHKD                           │  │
│  │  • Autenticación X11 y teclados: Xauth, Setxkbmap (US / Latam)   │  │
│  │  • Terminal: Alacritty (Tema Catppuccin)                         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Stack Aprobado

| Componente | Selección | Descripción |
| :--- | :--- | :--- |
| **Administrador de Ventanas** | `bspwm` | Gestor de mosaico basado en partición binaria |
| **Atajos de Teclado** | `sxhkd` | Demonio simple de teclas de X11 |
| **Barra de Estado** | `polybar` | Barra completa de borde a borde con detección dinámica de batería y red |
| **Lanzador de Apps** | `rofi` | Menú de aplicaciones y menú de energía |
| **Compositor** | `picom` | Sombras, esquinas redondeadas y opacidad |
| **Notificaciones** | `dunst` | Servidor ligero de notificaciones |
| **Fondo de Pantalla** | `feh` | Gestor de fondos con selector interactivo |
| **Audio / Multimedia** | PipeWire y Playerctl | Audio moderno con integración MPRIS |

---

## 🚀 Instalación y Uso Rápido

### 1. Instalación Standalone (Recomendado)

```bash
mkdir -p "$HOME/.dotfiles/wm"
git clone https://github.com/anthonyportugal/bspwm.git "$HOME/.dotfiles/wm/bspwm"
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
