# Buenas prácticas — tiny-proxy-tailscale

> Consejos operativos para mantener el proxy estable, evitar baneos y no romper el hardware.

---

## 📡 Gestión de IPs y rotación

### Los carriers tienen "pools" de IPs jerarquizados

No todas las IPs son iguales. Tu operadora clasifica:

| Tier | Descripción | Tu experiencia |
|------|-------------|----------------|
| **Tier 1 — Limpia** | Usuarios normales, sesiones estables | IPs con buena reputación, ningún captcha |
| **Tier 2 — Gris** | Rotaron recientemente, ratio de tráfico raro | Algunos sitios con captcha, latencia extra |
| **Tier 3 — Penalizada** | Heavy rotation, scraping detectado, CGNAT agresivo | Cloudflare 403, DNSBLs, sesiones rotas |

El objetivo es **permanecer en Tier 1**.

---

### 🍯 Reglas de oro para rotar IPs

1. **Rotar solo cuando falla** — no por rutina ni por tiempo
2. **Mínimo 15 min de sesión** después de cada rotación para que el carrier te marque como estable
3. **Chequear calidad de la IP nueva** antes de declararla buena (ver `scripts/ip_score.sh`)
4. **Máximo 10 rotaciones/hora** — idealmente menos
5. **Preferir dual SIM > airplane mode** si tu dispositivo lo soporta
6. **Si caés en CGNAT doble** (IP 100.x en ipinfo.io), esa operadora no sirve para este caso de uso

---

### ⚠️ El modo avión no quema la SIM

La SIM es un chip pasivo sin partes móviles. Lo que **sí** puede pasar con uso excesivo de `airplane.sh`:

| Riesgo | Causa | Límite seguro |
|--------|-------|---------------|
| **Throttling de operadora** | Re-registros masivos detectados como anómalo | ≤10/hr |
| **Desgaste térmico del modem** | Handshake completo cada vez (banda, auth, IP) | ≤50/día |
| **Batería** | Cada ciclo consume ~3-5% extra vs reposo | no activo 24/7 |
| **IP pegajosa / pool penalty** | Carrier detecta rotador, te degrada de pool | ≥15 min entre ciclos |
| **Re-registro fallido** | Modem atorado buscando red si no termina ciclo anterior | min 10s de delay en script |

> **Regla práctica:** máximo 1 rotación cada 5 minutos, máximo 10 por hora. El hardware y la operadora están seguros.

---

### 📊 Verificar calidad de IP antes de quedarse

Usá `scripts/ip_score.sh` para puntuar tu IP actual antes de usarla como proxy:

```bash
# Salida legible
./scripts/ip_score.sh

# Salida JSON (para integrar en API)
./scripts/ip_score.sh --json
```

**Qué mide:**
- CGNAT / doble NAT (penalización fuerte)
- ISP marcado como hosting/proxy/datacenter
- Geolocalización

**Score:**
- `≥80` → 🟢 mantener
- `50-79` → 🟡 usable con precaución
- `<50` → 🔴 rotar

---

### 🔄 Alternativas más saludables que airplane mode

| Estrategia | Cómo | Ventaja |
|------------|------|---------|
| **Dual SIM** | Alternar datos entre SIM 1 y SIM 2 | Cambia de carrier y pool, sin togglear radio |
| **WiFi fallback** | Cambiar a WiFi → volver a datos | La operadora no ve rotación, solo sesión de datos nueva |
| **IPv6 preferente** | Si tu carrier da IPv6, forzar conexiones por ahí | Pools enormes, menos saturados |
| **Esperar expiración natural** | Algunas operadoras te renuevan IP cada X min sin tocar nada | Zero riesgo, zero wear |

**Cambiar datos a SIM 2 (si tenés dual SIM):**
```bash
su -c "settings put global mobile_data1 1"
su -c "settings put global mobile_data0 0"
sleep 5
# Verificar nueva IP
ip addr show rmnet_data0 | grep 'inet '
```

---

## 🛡️ Seguridad de la API

Si exponés endpoints para controlar el proxy remotamente, estos son los mínimos indispensables:

### Autenticación
- API key en header (`X-Api-Key: tukey`), nunca en query string ni URL
- Key almacenada en variable de entorno, nunca hardcodeada en el repo

### Rate limiting por endpoint

| Endpoint | Riesgo | Límite recomendado |
|----------|--------|-------------------|
| `POST /proxy/start` | DoS por múltiples instancias | max 1/min |
| `POST /proxy/stop` | Dejar proxy caído | max 1/min |
| `POST /network/rotate` | Quemar IP pool, throttling | min 60s entre llamadas, max 10/hr |
| `GET /logs/*` | Leak de datos | sin límite pero sin secretos en logs |

### Whitelist de comandos
Nunca ejecutés input del usuario. El endpoint `POST /run/<script>` debe consultar una **whitelist JSON** fija en el servidor:

```json
{
  "allowed": {
    "status": "scripts/status.sh",
    "health": "health",
    "start": "scripts/start.sh",
    "stop": "scripts/stop.sh",
    "rotate": "scripts/airplane.sh",
    "ipscore": "scripts/ip_score.sh"
  }
}
```

Si `script` no está en esa lista → `400 Bad Request`.

### Timeout en subprocess
```python
# Python ejemplo
result = subprocess.run(
    ["bash", allowed[script]],
    capture_output=True,
    text=True,
    timeout=30  # nunca más de 30s, así el script no bloquea
)
```

---

## 📦 Dependencias recomendadas para API mínima

| Ecosistema | Lenguaje | Instalación en Termux | Notas |
|-----------|---------|----------------------|-------|
| **FastAPI + uvicorn** | Python | `pkg install python python-pip && pip install fastapi uvicorn` | Recomendado: async, auto-docs, liviano |
| **Flask** | Python | `pip install flask` | Más simple, suficiente si no necesitás async |
| **Go stdlib (net/http)** | Go | `pkg install golang` | Binary único, más eficiente en RAM |

> **Sugerencia:** Para este proyecto (scripts en bash, conectividad Tailscale, posiblemente lento en red móvil), **Python + FastAPI** es el sweet spot.

---

## 🔧 Integración con `health`

El script `health` ya verifica:
- Interfaz Tailscale (`tailscale0` o `tun0`)
- Proceso `tinyproxy` corriendo
- Conectividad a internet
- DNS Tailscale (`100.100.100.100`)
- Proxy respondiendo por Tailscale IP

**No repetir esto en la API.** Reutilizar el script existente vía `subprocess` o llamar sus funciones siempre que sea posible.

---

## 🏁 Checklist antes de dejar corriendo 24/7

- [ ] `tinyproxy` escucha en `0.0.0.0:8888` y en `tailscale0`
- [ ] La app de Tailscale está conectada y fijada ("always-on VPN" si el SO lo permite)
- [ ] Termux tiene wake lock (`termux-wake-lock`)
- [ ] `keepalive.sh` o servicio similar vigila que tinyproxy no se caiga
- [ ] La API (si existe) tiene rate limiting y auth
- [ ] Se probó `ip_score.sh` y la IP está en Tier 1
- [ ] Se configuró `cron` o `termux-job-scheduler` para health check periódico
- [ ] Logs rotan (no llenan almacenamiento)

---

## 📚 Referencias relacionadas

- [`docs/bug_tailscale_pkg.md`](bug_tailscale_pkg.md) — Por qué la app oficial de Tailscale en vez de CLI Linux
- [`scripts/airplane.sh`](../scripts/airplane.sh) — Toggle de modo avión para rotar IP
- [`scripts/ip_score.sh`](../scripts/ip_score.sh) — Score de calidad de IP (nuevo)
- [`AGENT.md`](../AGENT.md) — Contexto completo del proyecto
