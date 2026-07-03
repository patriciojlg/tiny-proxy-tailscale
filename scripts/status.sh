#!/data/data/com.termux/files/usr/bin/env bash
# Status de tinyproxy y Tailscale
set -uo pipefail

SOCK="/data/data/com.termux/files/home/tailscaled.sock"

echo "=== tinyproxy ==="
if pgrep -x tinyproxy >/dev/null 2>&1; then
    echo "  Estado: CORRIENDO (PID: $(pgrep -x tinyproxy))"
else
    echo "  Estado: DETENIDO"
fi

echo ""
echo "=== Tailscale ==="
TSIP=""
if ip addr show tailscale0 >/dev/null 2>&1; then
    TSIP=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    echo "  App oficial: CONECTADA ✅"
    echo "  Tailscale0 IP: $TSIP"
else
    echo "  App oficial: NO DETECTADA ⚠️"
    echo "    Abrí la app de Tailscale en Android y conectate."
fi

if pgrep -x tailscaled >/dev/null 2>&1; then
    echo ""
    echo "  Tailscale CLI: CORRIENDO (PID: $(pgrep -x tailscaled))"
    echo "  Tailscale CLI IP:"
    tailscale --socket="$SOCK" ip -4 2>/dev/null || echo "    (no disponible)"
    echo ""
    echo "  Tailscale CLI status:"
    tailscale --socket="$SOCK" status 2>&1 || true
fi

echo ""
echo "=== Proxy URL ==="
if [ -n "$TSIP" ]; then
    echo "  http://$TSIP:8888"
else
    echo "  (aún no detectada tailscale0 — conectate desde la app oficial)"
fi
