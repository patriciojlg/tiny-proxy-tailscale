# tiny-proxy-tailscale

> Proxy SOCKS5/HTTP ligero + conexión segura via Tailscale para Android rooteado.

## ¿Qué hace?

Este proyecto aborda la **configuración y prestación de un servicio de proxy accesible vía Tailscale**. El proxy corre en este mismo **teléfono Android rooteado** con `tinyproxy` y se hace visible a través de Tailscale para otras máquinas o servicios.

- Expone un proxy HTTP/SOCKS5 local mínimo (`tinyproxy`)
- Hace el proxy accesible remotamente a través de la red mesh segura de Tailscale
- Útil para automatizaciones, scraping, o acceso remoto a servicios del teléfono

## Estructura

```
├── config/     # Archivos de configuración
├── docs/       # Documentación
├── scripts/    # Scripts de setup y utilidad
└── src/        # Código fuente (si aplica)
```

## Requisitos

- Android rooteado
- Termux
- Tailscale (`pkg install tailscale`)

## TODO

- [ ] Instalar y configurar `tinyproxy` en Android/Termux
- [ ] Crear archivo de configuración de tinyproxy en `config/tinyproxy.conf`
- [ ] Configurar Tailscale para exponer el puerto del proxy (tailscale up --accept-routes / anunciar)
- [ ] Crear scripts de arranque/parada en `scripts/`
- [ ] Verificar conectividad del proxy desde otro nodo Tailscale
- [ ] Documentar pasos de setup en `docs/SETUP.md`
- [ ] Agregar reglas de firewall/iptables si es necesario (dispositivo rooteado)
- [ ] Crear health-check o script de monitoreo del servicio
- [ ] Opcional: contenedor o servicio systemd/termux-services para persistencia

## Uso

(TODO)
