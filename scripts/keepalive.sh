#!/data/data/com.termux/files/usr/bin/env bash
# Keepalive: reinicia tinyproxy si se cae; detecta app oficial de Tailscale
set -euo pipefail

# Wake lock
termux-wake-lock 2>/dev/null || true

# Si tinyproxy no corre, levantarlo
if ! pgrep -x tinyproxy >/dev/null 2>&1; then
    tinyproxy -c "$(dirname "$0")/../config/tinyproxy.conf"
fi

# Silencioso para cron/script periódico:
# ip addr show tailscale0 >/dev/null 2>&1 || :
