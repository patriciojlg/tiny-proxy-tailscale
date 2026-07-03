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

## Estructura esperada

```
├── config/     # tinyproxy.conf, tailscale config, etc.
├── docs/       # Documentación del setup
├── scripts/    # Scripts de arranque, setup, health-check
└── src/        # Código auxiliar si aplica
```
