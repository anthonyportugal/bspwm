# Instrucciones para agentes y colaboradores

Estas reglas aplican a todo el repositorio.

## Antes de cambiar archivos

1. Leer `README.md`, `docs/archcraft-audit.md` y este archivo completos.
2. Revisar `git status` y preservar cambios ajenos.
3. Confirmar que el paso o checkpoint esté autorizado explícitamente.
4. No anunciar como funcional una capacidad que sólo exista en el roadmap.

## Flujo de trabajo

Trabajar en verticales pequeños: inspeccionar, proponer, implementar, validar,
revisar el diff y detenerse. No hacer commits, pushes, tags ni cambios remotos
sin autorización explícita del usuario.

## Convención de commits

Cuando un commit esté explícitamente autorizado:

- usar `emoji type(scope): subject` según gitmoji y Conventional Commits;
- escribir el subject en inglés y en modo imperativo;
- comenzar en minúscula la primera palabra después de `:`;
- revisar el staged y verificar la firma antes de hacer push.

## Límites arquitectónicos y ownership

- Este repositorio debe instalarse de forma 100% autónoma, sin depender del
  repositorio base, MangoWM ni de una capa privada.
- Sólo administra la sesión X11 (bspwm, sxhkd, polybar, rofi, dunst, picom y
  sus scripts asociados en `.config/bspwm`).
- No administra identidades, secretos, drivers, display manager ni configuración
  GPU global.
- No introducir nombres fijos de monitores (`DP-0`, `HDMI-1`), interfaces de red
  (`enp3s0`), baterías (`BAT1`), backlights o paths propios de una máquina.
- Precedencia acordada: defaults públicos → override privado opcional → override
  local de máquina (`local.env`).
- Archivos de runtime, caches y selección activa pertenecen a
  `$XDG_STATE_HOME/bspwm`; nunca deben reescribir el checkout versionado.
- Cada dependencia consumida se declara en `packages/` de este repositorio.

## Stow y bootstrap

- `home/` es el único stow directory y contiene el paquete `bspwm`.
- Usar siempre `--dir`, `--target`, `--no-folding`, dry-run y detección de
  conflictos; nunca ejecutar `stow --adopt`.
- `bin/bspwm` expone `bootstrap`, `doctor` y `unlink`, es dry-run por defecto e
  idempotente; preservar este contrato público.
- No ejecutar instalación de paquetes ni Stow con privilegios globales de root.

## Documentación vigente de herramientas

Cuando una tarea dependa del uso, configuración, API o sintaxis actual de una
librería, framework, SDK, CLI o servicio cloud, consultar Context7 antes de
responder o implementar, aunque la herramienta sea conocida. No es necesario
para refactors internos, scripts desde cero, lógica de negocio, code review o
conceptos generales.

Flujo requerido:

```bash
pnpm dlx ctx7@latest library <nombre-oficial> "<consulta específica>"
pnpm dlx ctx7@latest docs </org/proyecto> "<concepto específico>"
```

Resolver siempre el ID antes de pedir documentación, salvo que el usuario haya
dado directamente un ID `/org/proyecto`.

## Validación

Cuando se modifiquen el bootstrap, manifests o scripts de sesión:

```bash
bash -n bin/bspwm tests/*.sh home/bspwm/.config/bspwm/scripts/*
shellcheck bin/bspwm tests/*.sh tests/fakes/* home/bspwm/.config/bspwm/scripts/*
./tests/bootstrap-smoke.sh
./tests/session-smoke.sh
git diff --check
```

Los smoke tests sólo instalan enlaces bajo targets temporales y usan backends
falsos; nunca deben instalar paquetes en el sistema host.
