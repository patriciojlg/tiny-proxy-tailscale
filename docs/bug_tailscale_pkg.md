# Bug: `tailscaled` sigue crasheando tras autenticación (SIGSYS faccessat2)

## Resumen

El binario oficial de Tailscale para Linux `arm64` crashea en Android (aunque esté en Termux) con `SIGSYS: bad system call` en el momento exacto de loguearse exitosamente. Esto ocurre porque Android bloquea la syscall `faccessat2` vía seccomp, y `tailscaled` la invoca al verificar auto-updates.

## Entorno del bug

| Campo | Valor |
|-------|-------|
| SO | Android (rooteado) |
| Ejecución | Termux |
| Arquitectura | `arm64-v8a` (aarch64) |
| Kernel | `4.14.186-perf-00289-g570b5047116b` |
| Bins probados | `tailscaled` 1.98.8 y 1.94.1 (oficial arm64 tarball) |
| Síntoma | Crash justo después del login exitoso, al recibir netmap del control plane |
| Error fatal | `SIGSYS: bad system call` en `syscall.faccessat2` (syscall 0x1b7 = 439) |

## Stack trace clave

```
SIGSYS: bad system call
PC=0x133f0 m=... sigcode=1

goroutine ... [syscall]:
syscall.Syscall6(0x1b7, ...)   // 0x1b7 = 439 = faccessat2
syscall.faccessat2(...)
os/exec.findExecutable(...)
tailscale.com/clientupdate.haveExecutable(...)
tailscale.com/clientupdate.canAutoUpdate()
tailscale.com/feature.CanAutoUpdate()
tailscale.com/ipn/ipnlocal.(*LocalBackend).onTailnetDefaultAutoUpdate(...)
```

El crash se produce porque `onTailnetDefaultAutoUpdate()` triggerea un check de auto-update que usa `os/exec.LookPath`, que en Go ≥ 1.25 usa `faccessat2` para comprobar si un ejecutable es accesible. Android kernels viejos o configuran seccomp para denegar esta syscall.

## Versiones probadas

| Versión Tailscale | Resultado |
|-------------------|-----------|
| 1.98.8 (arm64) | ❌ SIGSYS tras login |
| 1.94.1 (arm64) | ❌ SIGSYS tras login |

También se probó `userspace-networking` (modo sin root/TUN) y el crash ocurre exactamente igual, ya que no está relacionado con el TUN sino con el logueo y control plane.

## Log del crash (últimas líneas completas)

De la versión 1.98.8:

```
2026/07/03 16:34:13 control: RegisterReq: got response; machineAuthorized=true; authURL=false
2026/07/03 16:34:14 control: netmap: got new dial plan from control
SIGSYS: bad system call
PC=0x19500 m=13 sigcode=1

syscall.Syscall6(0x1b7, 0xffffffffffffff9c, ...)
...onTailnetDefaultAutoUpdate...
```

## Causa raíz

`faccessat2` (syscall 439 en arm64) es relativamente nueva (Linux 5.8+, glibc 2.32+). Android, incluso con kernels parcheados por OEM, filtra esta syscall via seccomp. Go 1.26 (y Go 1.25) la usa dentro de `os/exec.LookPath` en Linux cuando está disponible. Tailscale la triggerea indirectamente porque detecta si hay un "updater" disponible en el sistema.

## Workarounds probados / descartados

- **`--tun=userspace-networking`** → sigue crasheando (no es de TUN).
- **Bajar a versión más vieja** → también crashea con el mismo stack trace si usa Go reciente.
- **Patch con seccomp-bpf personalizado** → complejo, requiere root + conocimientos de kernel.
- **Compilar tailscale para Android/arm con `GOOS=android`** → implica tener Go completo en Termux y recompilar; es la solución "correcta" pero pesada.

## Solución adoptada

**Usar la aplicación oficial de Tailscale para Android** desde Play Store / F-Droid / APK directo.

- La APK oficial está compilada contra el runtime de Android (`GOOS=android`), no contra Linux estándar, y usa las syscall disponibles.
- Corre en su propio sandbox con permisos de VPN, creando la interfaz TUN necesaria.
- Funciona sin root (y funciona mejor que los bins de Linux). Con root, puede correr en modo socks5/proxy sin problemas.

## Integración con el proyecto actual

Este repositorio (`tiny-proxy-tailscale`) ahora cambia de estrategia:

1. **Tailscale** → usa la **app oficial de Android**, no la CLI de Linux.
2. **tinyproxy** → sigue corriendo en **Termux** como antes, para escuchar en todas las interfaces.
3. **Conectividad** → la app de Tailscale crea `tailscale0` (VPN), y tinyproxy escucha en `0.0.0.0`, por lo que es accesible desde la tailnet.

### Scripts ajustados

Los scripts de `scripts/` detectarán si la CLI de Tailscale está funcionando y darán preferencia a ella; si no, asumen que Tailscale corre por la app oficial y solo gestionan `tinyproxy`.

## Troubleshooting futuro

Si alguien quiere insistir con la CLI de Linux en Android, las opciones son:

1. **Compilar Tailscale con `GOOS=android`** (cross-compile o en Termux con Go).
2. **Usar un binario Termux-explicito** si aparece en repos de la comunidad (ej: `termux-user-repository`).
3. **Esperar** a que Tailscale libere un binario Android standalone (no solo la APK).

## Referencias

- Tailscale issue relacionado: https://github.com/tailscale/tailscale/issues/ (buscar "faccessat2 android" o "SIGSYS userspace networking").
- Go issue sobre `os/exec` y `faccessat2`: https://github.com/golang/go/issues/ (invoca seccomp en Android).
