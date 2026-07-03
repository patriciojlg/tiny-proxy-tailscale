#!/data/data/com.termux/files/usr/bin/env bash
# ip_score.sh — Score de calidad de IP móvil para tiny-proxy-tailscale
# Uso: ./ip_score.sh [--json]
# Salida: score 0-100 con advertencias y recomendación

set -uo pipefail

JSON=false
if [ "${1:-}" = "--json" ]; then
    JSON=true
fi

IP=$(curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null)
SCORE=100
WARNINGS=()
J_WARNINGS=""

if [ -z "$IP" ]; then
    if $JSON; then
        echo '{"ok":false,"error":"sin conectividad para verificar IP"}'
    else
        echo "❌ Sin conectividad para verificar IP"
    fi
    exit 1
fi

# Penalización CGNAT / RFC1918
if [[ "$IP" =~ ^100\.([6-9][4-9]|1[0-1][0-9]|12[0-7])\. ]]; then
    SCORE=$((SCORE - 30))
    WARNINGS+=("CGNAT detectado (100.64+)")
fi

if [[ "$IP" =~ ^10\. ]] || [[ "$IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    SCORE=$((SCORE - 40))
    WARNINGS+=("IP RFC1918 — doble NAT probable")
fi

# Geo / ISP
COUNTRY=$(curl -s --max-time 5 "http://ip-api.com/json/${IP}?fields=countryCode" 2>/dev/null | jq -r '.countryCode // "unknown"')
ISP=$(curl -s --max-time 5 "http://ip-api.com/json/${IP}?fields=isp" 2>/dev/null | jq -r '.isp // "unknown"')

case "$ISP" in
    *"hosting"*|*"cloud"*|*"vps"*|*"proxy"*|*"datacenter"*)
        SCORE=$((SCORE - 20))
        WARNINGS+=("ISP marcado como hosting/proxy")
        ;;
esac

# Formatear advertencias JSON
for w in "${WARNINGS[@]}"; do
    J_WARNINGS="${J_WARNINGS}\"$w\","
done
J_WARNINGS="[${J_WARNINGS%,}]"

# Clasificación
CLASS=""
RECOMMEND=""
if [ $SCORE -lt 50 ]; then
    CLASS="low"
    RECOMMEND="rotar"
elif [ $SCORE -lt 80 ]; then
    CLASS="medium"
    RECOMMEND="precaucion"
else
    CLASS="high"
    RECOMMEND="mantener"
fi

if $JSON; then
    cat <<EOF
{"ok":true,"ip":"$IP","country":"$COUNTRY","isp":"$ISP","score":$SCORE,"class":"$CLASS","recommend":"$RECOMMEND","warnings":$J_WARNINGS}
EOF
else
    echo "📡 IP pública: $IP"
    echo "🌍 País:       $COUNTRY"
    echo "🏢 ISP:        $ISP"
    echo ""
    echo "⭐ SCORE: $SCORE/100"
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "⚠️  Advertencias:"
        for w in "${WARNINGS[@]}"; do echo "   - $w"; done
    fi
    case "$CLASS" in
        low)    echo "🔴 IP de baja calidad — considerar rotar" ;;
        medium) echo "🟡 IP usable con precaución" ;;
        high)   echo "🟢 IP de buena calidad — mantener" ;;
    esac
fi
