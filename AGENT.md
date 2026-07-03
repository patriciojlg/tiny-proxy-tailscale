# Contexto del Agente IA — tiny-proxy-tailscale

> **IMPORTANTE:** Este proyecto corre en un **teléfono Android rooteado**.

## Descripción del proyecto

Este proyecto aborda la configuración y prestación de un **servicio de proxy accesible vía Tailscale**:

- El proxy corre en este mismo teléfono Android (rooteado) usando `tinyproxy`.
- Se hace visible a través de **Tailscale** para que otras máquinas o servicios puedan usarlo.
- Todo el tráfico viaja por la mesh segura de Tailscale.

## Stack y entorno

- **OS:** Android rooteado
- **Entorno de ejecución:** Termux (o similar)
- **Proxy:** tinyproxy
- **VPN/mesh:** Tailscale
- **Casos de uso:** automatizaciones, scraping, acceso remoto a servicios del teléfono

## Restricciones importantes

- Dispositivo real con root: se dispone de permisos de superusuario si se requiere
- Recursos limitados comparados con un servidor tradicional
- Batería y conectividad móvil/WiFi son variables
- Tailscale debe estar instalado y autenticado en el dispositivo

## Nota sobre Tailscale Play Store en Android

Cuando Tailscale está instalado desde la Play Store en Android, la app usa el framework nativo `VpnService` de Android. Esto crea una interfaz **`tun0`** en lugar de la tradicional `tailscale0` que se ve en Linux.

### Consecuencias prácticas

- **No existe** el comando `tailscale` accesible desde Termux/CLI.
- **No existe** la interfaz `tailscale0`.
- **Sí existe** la interfaz `tun0` con la IP de Tailscale del nodo (por ejemplo, `100.115.32.125`).
- Las rutas a nodos de la red (`100.x.x.x`) se dirigen por `tun0` (en routing table `1036`).
- Las rutas IPv6 de Tailscale (`fd7a:115c:a1e0::/48`) también están presentes en `tun0`.
- **`tailscale status` no funciona** desde Termux porque el binario CLI no está en el `$PATH` del sistema.

### Verificación alternativa

Se puede confirmar la conectividad a Tailscale desde Termux usando:

```bash
ip route show table all | grep tun0          # ver rutas 100.x
ip -s link show tun0                          # ver interfaz activa
ping 100.100.100.100                         # DNS de Tailscale
```

## Estructura esperada

```
├── config/     # tinyproxy.conf, tailscale config, etc.
├── docs/       # Documentación del setup
├── scripts/    # Scripts de arranque, setup, health-check
└── src/        # Código auxiliar si aplica
```
