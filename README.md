# tiny-proxy-tailscale

> Proxy HTTP ligero expuesto vía Tailscale para Android rooteado.

## ¿Qué hace?

Este proyecto aborda la **configuración y prestación de un servicio de proxy accesible vía Tailscale**. El proxy corre en este mismo **teléfono Android rooteado** con `tinyproxy` y se hace visible a través de Tailscale para otras máquinas o servicios.

- Expone un proxy HTTP local mínimo (`tinyproxy`) escuchando en `0.0.0.0`
- Hace el proxy accesible remotamente a través de la red mesh segura de Tailscale
- Útil para automatizaciones, scraping, o acceso remoto a servicios del teléfono

## Estado del proyecto

| Componente | Estado |
|---|---|
| Instalar `tinyproxy` | ✅ Hecho (v1.11.3) |
| Instalar `tailscale` | ✅ Hecho (v1.98.8 — binario oficial arm64) |
| Configurar `tinyproxy` | 🔄 Pendiente |
| Exponer proxy por Tailscale | 🔄 Pendiente |
| Scripts de arranque/parada | 🔄 Pendiente |
| Verificar conectividad | 🔄 Pendiente |

## Requisitos

- Android rooteado
- Termux
- `pkg` funcionando (repos actualizados)

## Guía de implementación

### Fase 1 – Entorno (hecho)

```bash
pkg update
pkg install tinyproxy   # ya instalado: v1.11.3
```

### Fase 2 – Instalar Tailscale (hecho)

Tailscale no está en los repos de Termux. Se descargó e instaló el binario oficial `arm64`:

```bash
# Descargar la última versión estable
VERSION=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest \
    | grep -oE '"tag_name": "v[^"]+"' | head -1 | sed 's/"tag_name": "v//;s/"//')
curl -fSL "https://pkgs.tailscale.com/stable/tailscale_${VERSION}_arm64.tgz" \
    -o "$HOME/tailscale_arm64.tgz"

# Extraer e instalar
tar xzf "$HOME/tailscale_arm64.tgz" -C "$HOME"
cp "$HOME"/tailscale_*/tailscale "$HOME"/tailscale_*/tailscaled "$PREFIX/bin/"
chmod +x "$PREFIX/bin/tailscale" "$PREFIX/bin/tailscaled"
rm -rf "$HOME"/tailscale_*

# Verificar
tailscale version   # 1.98.8 ✅
```

### Fase 3 – Configurar Tailscale

```bash
# Loguear/auth en Tailscale
tailscale up

# Verificar que se creó la interfaz tailscale0
ip addr show tailscale0

# Obtener tu IP de Tailscale
tailscale ip -4
```

### Fase 4 – Configurar tinyproxy

El archivo `config/tinyproxy.conf` del repo se usa como base. Edita según tu caso:

```conf
# Escuchar en todas las interfaces (incluida tailscale0)
Listen 0.0.0.0
Port 8888

# Permitir conexiones desde la red de Tailscale (ejemplo: 100.x.x.x/8)
Allow 127.0.0.1
Allow 10.0.0.0/8
Allow 100.64.0.0/10
Allow 172.16.0.0/12
Allow 192.168.0.0/16

# Desactivar filtros para uso simple
FilterDefaultDeny No

# Logs en Termux (opcional)
LogLevel Info
```

```bash
# Probar tinyproxy con la config
tinyproxy -d -c config/tinyproxy.conf
```

### Fase 5 – Scripts de gestión

Usa los scripts en `scripts/` del repo:

```bash
# Iniciar ambos servicios
./scripts/start.sh

# Detener
./scripts/stop.sh

# Ver estado
./scripts/status.sh
```

### Fase 6 – Verificar conectividad

Desde otra máquina con Tailscale:

```bash
# Reemplaza <tailscale-ip-del-telefono> con la IP obtenida en Fase 3
curl -x http://<tailscale-ip-del-telefono>:8888 -I https://www.google.com
```

## TODO

- [x] Instalar `tinyproxy` en Termux
- [x] Instalar `tailscale` (binario oficial arm64)
- [ ] Crear `config/tinyproxy.conf` funcional
- [ ] Crear scripts `scripts/start.sh`, `scripts/stop.sh`, `scripts/status.sh`
- [ ] Autenticar y levantar Tailscale (`tailscale up`)
- [ ] Verificar conectividad del proxy desde otro nodo Tailscale
- [ ] Documentar pasos en `docs/SETUP.md`
- [ ] Agregar reglas `iptables` si es necesario (dispositivo rooteado)
- [ ] Crear health-check / monitoreo
- [ ] Opcional: persistencia con `termux-services` o `crond` + script de arranque

## Estructura

```
.
├── AGENT.md            # Contexto del agente IA
├── config/
│   └── tinyproxy.conf  # Configuración del proxy
├── docs/
│   └── SETUP.md        # Documentación detallada
├── scripts/
│   ├── start.sh
│   ├── stop.sh
│   └── status.sh
├── src/                # Código auxiliar si aplica
└── README.md           # Este archivo
```

## Notas de Android rooteado

- Se dispone de `iptables` (vía `su -c iptables`) si se necesita filtrar tráfico
- Puedes abrir puertos en cualquier interfaz (incluida `tailscale0`) gracias al root
- Considera el impacto en batería al correr servicios permanentes

## Uso

Una vez configurado, apunta cualquier cliente HTTP a:

```
http://<tailscale-ip-del-telefono>:8888
```

El proxy transparente de Tailscale se encarga del enrutamiento seguro.
