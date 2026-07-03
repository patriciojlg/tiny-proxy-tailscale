#!/data/data/com.termux/files/usr/bin/env bash
# Start tinyproxy + tailscale daemon (userspace mode) fallback
set -euo pipefail

SOCK="/data/data/com.termux/files/home/tailscaled.sock"
STATE="/data/data/com.termux/files/home/tailscaled.state"
STATEDIR="/data/data/com.termux/files/home/tailscale_state"
TINYLOGDIR="/data/data/com.termux/files/home/.local/share/tinyproxy"
TPIDFILE="$TINYLOGDIR/tinyproxy.pid"

# Asegurar directorios
mkdir -p "$STATEDIR" "$TINYLOGDIR"

# Wake lock (evita que Android suspenda Termux)
termux-wake-lock 2>/dev/null || true

# Intentar levantar tailscaled CLI solo si está disponible
# NOTA: En Android, la app oficial de Tailscale es la forma estable.
TAILSCALE_CLI_OK=false
if command -v tailscaled >/dev/null 2>&1; then
    if tailscaled --version >/dev/null 2>&1; then
        echo "==> Intentando iniciar tailscaled CLI (fallback)..."
        if ! pgrep -x tailscaled >/dev/null 2>&1; then
            nohup tailscaled \
                --tun=userspace-networking \
                --state="$STATE" \
                --statedir="$STATEDIR" \
                --socket="$SOCK" \
                >/dev/null 2>&1 &
            sleep 2
            if pgrep -x tailscaled >/dev/null 2>&1; then
                TAILSCALE_CLI_OK=true
                echo "    tailscaled CLI PID: $(pgrep -x tailscaled)"
            else
                echo "    ⚠️ tailscaled CLI no pudo iniciarse (ver bug)."
            fi
        else
            TAILSCALE_CLI_OK=true
            echo "    tailscaled CLI ya corriendo (PID: $(pgrep -x tailscaled))"
        fi
    fi
fi

# Mostrar estado de la app oficial
echo ""
echo "==> Recomendación: usar app oficial de Tailscale en Android"
if ip addr show tailscale0 >/dev/null 2>&1; then
    TSIP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    echo "    ✅ tailscale0 detectada — app oficial conectada"
    echo "    Tailscale IP: $TSIP"
else
    echo "    ⚠️ No se detectó tailscale0. Abrí la app de Tailscale y conectate."
fi

if [ "$TAILSCALE_CLI_OK" = true ]; then
    echo ""
    echo "==> Tailscale CLI status:"
    tailscale --socket="$SOCK" status 2>&1 || true
fi

echo ""
echo "==> Iniciando tinyproxy..."
if ! pgrep -x tinyproxy >/dev/null 2>&1; then
    tinyproxy -c "$(dirname "$0")/../config/tinyproxy.conf"
    sleep 1
    echo "    tinyproxy PID: $(pgrep -x tinyproxy)"
else
    echo "    tinyproxy ya corriendo (PID: $(pgrep -x tinyproxy))"
fi

echo ""
echo "==> Proxy listo en:"
if [ -n "${TSIP:-}" ]; then
    echo "    http://$TSIP:8888"
else
    echo "    http://<tailscale-ip-del-telefono>:8888"
fi
echo ""
