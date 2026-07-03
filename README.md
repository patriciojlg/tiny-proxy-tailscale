# tiny-proxy-tailscale

> Proxy HTTP ligero expuesto vía Tailscale para Android.

## ¿Qué hace?

Este proyecto configura un proxy HTTP (`tinyproxy`) dentro de **Termux** para que sea accesible desde tu red **Tailscale**.

- El proxy corre localmente en el teléfono con `tinyproxy` escuchando en `0.0.0.0`
- **Tailscale** corre a través de la **app oficial de Android**, creando la interfaz `tailscale0` con tu IP de la tailnet
- Otros nodos Tailscale pueden usar el proxy pointing a `http://<tu-ip-tailscale>:8888`
- Script `scripts/airplane.sh` para forzar el cambio de IP del plan de datos (toggle de modo avión programático, requiere root)
- Útil para automatizaciones, scraping, o acceso remoto a servicios del teléfono

## ¿Por qué la app oficial?

Los binarios oficiales de Tailscale para Linux (`arm64`) crashean en Android con `SIGSYS: bad system call` al autenticarse, debido a que Android bloquea la syscall `faccessat2` vía seccomp (ver `docs/bug_tailscale_pkg.md`).

**Solución adoptada:** usar la app oficial de Tailscale para Android + tinyproxy en Termux.

## Requisitos

- Android (rooteado ayuda para chequeos de firewall, pero no es estrictamente necesario)
- [Termux](https://f-droid.org/packages/com.termux/) instalado
- **App oficial de Tailscale** instalada y conectada
- `tinyproxy` instalado vía `pkg install tinyproxy`

## Instalación

### 1. Instalar Tailscale (app oficial)

- Descargala desde [Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn), [F-Droid](https://f-droid.org/packages/com.tailscale.ipn/) o el [sitio oficial](https://tailscale.com/download/android).
- Abrí la app, logueate con tu cuenta, y activala.
- Asegurate de que figure como "Connected".

### 2. Instalar tinyproxy en Termux

```bash
pkg update
pkg install tinyproxy
```

### 3. Clonar o acceder a este repositorio dentro de Termux

```bash
cd ~/tiny-proxy-tailscale
```

### 4. Iniciar el proxy

```bash
./scripts/start.sh
```

Esto levanta `tinyproxy` escuchando en todas las interfaces. La app de Tailscale ya debe estar conectada.

### 5. Verificar

```bash
# Desde Termux
./scripts/status.sh

# Ver que tailscale0 existe
ip addr show tailscale0
```

### 6. Probar desde otro nodo Tailscale

Desde cualquier otra máquina con Tailscale:

```bash
# Reemplaza <ip-tailscale> con la IP de tu teléfono
curl -x http://<ip-tailscale>:8888 -I https://www.google.com
```

## Scripts

| Script | Uso |
|--------|-----|
| `./scripts/start.sh` | Levanta tinyproxy (y tailscaled CLI solo si detecta que funciona) |
| `./scripts/stop.sh` | Detiene tinyproxy (y tailscaled CLI si corre) |
| `./scripts/status.sh` | Estado de tinyproxy y conectividad Tailscale |
| `./scripts/keepalive.sh` | Para usar con `crond` o Tasker — asegura que tinyproxy siga corriendo |
| `./scripts/airplane.sh` | Requiere su/root — fuerza una nueva IP en datos alternando modo avión |

## Configuración

El archivo `config/tinyproxy.conf` contiene:

- `Listen 0.0.0.0` — escucha en todas las interfaces (incluida `tailscale0` si existe)
- `Port 8888`
- `Allow 100.64.0.0/10` — permite conexiones desde la red Tailscale
- Sin filtros (`FilterDefaultDeny No`)

## FAQ

### ¿Por qué no uso `tailscaled` directamente en Termux?

Por el bug documentado en `docs/bug_tailscale_pkg.md`. Los binarios Linux de Tailscale no funcionan en Android/Termux por restricciones de seccomp del kernel.

### ¿Necesito root?

No estrictamente. Con la app oficial de Tailscale podés tener VPN sin root. Root es útil solo si necesitás tocar `iptables` o ver interfaces del sistema directamente.

### Problemas de conectividad

Si otro nodo no llega al puerto 8888:

1. Verificá que la app de Tailscale esté conectada: `ip addr show tailscale0`
2. Verificá que tinyproxy esté corriendo: `./scripts/status.sh`
3. Si tenés root, podés verificar que no haya reglas de firewall bloqueando el puerto:
   ```bash
   su -c "iptables -L -n | grep 8888"
   ```

### Persistencia

Para que el proxy se inicie automáticamente al abrir Termux, agregá al final de `~/.bashrc`:

```bash
~/tiny-proxy-tailscale/scripts/start.sh
```

O usá **Tasker** para ejecutar periódicamente `scripts/keepalive.sh`.

## Estructura

```
.
├── AGENT.md                   # Contexto del agente IA
├── config/
│   └── tinyproxy.conf         # Configuración del proxy
├── docs/
│   ├── SETUP.md               # Documentación detallada
│   └── bug_tailscale_pkg.md   # Bug report: tailscale CLI en Android
├── scripts/
│   ├── start.sh
│   ├── stop.sh
│   ├── status.sh
│   └── keepalive.sh
├── src/                       # Código auxiliar si aplica
└── README.md                  # Este archivo
```

## Notas técnicas

- La app de Tailscale crea `tailscale0` en el sistema Android con las IPs de tu tailnet.
- tinyproxy en Termux escucha en `0.0.0.0`, por lo que atiende en `tailscale0` si el puerto no está bloqueado.
- Android/Termux puede dormir procesos en background — `termux-wake-lock` ayuda a mitigarlo.
- Si el teléfono está **rooteado**, se puede ejecutar `tinyproxy` como sistema bajo demanda, pero en la práctica no es necesario.
