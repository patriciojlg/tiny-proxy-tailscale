#!/data/data/com.termux/files/usr/bin/env bash
# Toggle airplane mode to force IP refresh on mobile data (requires root/su access)
set -euo pipefail

DELAY="${1:-10}"

if ! command -v su >/dev/null 2>&1; then
    echo "❌ No se encontró 'su'. Este script requiere root."
    exit 1
fi

echo "✈️  Activando modo avión..."
su -c "sh -c 'settings put global airplane_mode_on 1; am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true'"

echo "⏳ Esperando ${DELAY}s para que la antena libere la IP actual..."
sleep "$DELAY"

echo "🌐 Desactivando modo avión..."
su -c "sh -c 'settings put global airplane_mode_on 0; am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false'"

echo "✅ Modo avión desactivado. El dispositivo debería reconectar a datos y Wi-Fi."

# Pequeña pausa para que Android reconecte antes de leer IPs
sleep 3

WLAN_IP=""
CELLULAR_IP=""
if command -v ip >/dev/null 2>&1; then
    WLAN_IP=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || true)
    # En algunos dispositivos la interfaz móvil puede ser rmnet_data0, ccinet, etc.
    for iface in rmnet_data0 ccinet0 ccmni0 rmnet0 rmnet1; do
        if ip addr show "$iface" >/dev/null 2>&1; then
            CELLULAR_IP=$(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 || true)
            break
        fi
    done
fi

if [ -n "$WLAN_IP" ]; then
    echo "📶 Wi-Fi IP:    $WLAN_IP"
fi
if [ -n "$CELLULAR_IP" ]; then
    echo "📡 Datos IP:    $CELLULAR_IP"
fi
