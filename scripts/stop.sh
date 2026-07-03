#!/data/data/com.termux/files/usr/bin/env bash
# Stop tinyproxy + tailscale daemon (if running)
set -euo pipefail

SOCK="/data/data/com.termux/files/home/tailscaled.sock"
TPIDFILE="/data/data/com.termux/files/home/.local/share/tinyproxy/tinyproxy.pid"

echo "==> Deteniendo tinyproxy..."
if pgrep -x tinyproxy >/dev/null 2>&1; then
    pkill -x tinyproxy
    echo "    tinyproxy detenido"
else
    echo "    tinyproxy no estaba corriendo"
fi

echo "==> Deteniendo tailscaled CLI (si existe)..."
if pgrep -x tailscaled >/dev/null 2>&1; then
    pkill -x tailscaled
    echo "    tailscaled detenido"
else
    echo "    tailscaled no estaba corriendo"
fi

# Liberar wake lock
termux-wake-unlock 2>/dev/null || true

echo ""
echo "==> Servicios detenidos."
echo " 📌 La app oficial de Tailscale en Android sigue corriendo afuera de Termux."
echo "    Cerrala manualmente desde Android si querés desconectar."
