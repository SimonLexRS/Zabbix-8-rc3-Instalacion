#!/usr/bin/env bash
# Comprueba una instalación de Zabbix. Solo lee: no cambia nada.
set -u

fallos=0
ok()  { echo "✅ $1"; }
mal() { echo "❌ $1"; fallos=$((fallos + 1)); }

php_fpm=$(systemctl list-units --type=service --all --no-legend 'php*-fpm.service' | grep -oE 'php[0-9.]+-fpm' | head -1)

for s in postgresql nginx "${php_fpm:-php-fpm}" zabbix-server zabbix-agent2; do
  systemctl is-active -q "$s" && ok "Servicio activo: $s" || mal "Servicio detenido: $s"
  systemctl is-enabled -q "$s" && ok "Arranque automático: $s" || mal "Sin arranque automático: $s"
done

for p in 80 5432 10050 10051; do
  ss -tln | awk '{print $4}' | grep -qE ":$p$" && ok "Puerto en escucha: $p" || mal "Puerto cerrado: $p"
done

if command -v zabbix_get >/dev/null; then
  v=$(zabbix_get -s 127.0.0.1 -k agent.version 2>/dev/null)
  [ -n "$v" ] && ok "El agente responde: $v" || mal "El agente no responde a zabbix_get"
else
  echo "➖ zabbix_get no está instalado: se omite la prueba del agente"
fi

c=$(curl -s -o /dev/null -m 10 -w '%{http_code}' http://127.0.0.1/)
[ "$c" = 200 ] && ok "La web responde: HTTP $c" || mal "La web responde: HTTP $c"

a=$(curl -s -m 10 -H 'Content-Type: application/json-rpc' \
  -d '{"jsonrpc":"2.0","method":"apiinfo.version","params":{},"id":1}' \
  http://127.0.0.1/api_jsonrpc.php | grep -oE '"result":"[^"]+"')
[ -n "$a" ] && ok "La API responde: $a" || mal "La API no responde"

# Seguridad de PHP: ver docs/seguridad-php.md
log=$(ls /usr/share/doc/php*-fpm/changelog.Debian.gz 2>/dev/null | head -1)
if [ -n "$log" ] && zcat "$log" | grep -q 'CVE-2026-109618'; then
  ok "PHP tiene el parche de CVE-2026-109618 y 109619"
else
  mal "PHP sin el parche de CVE-2026-109618 y 109619"
fi

if grep -REqs '^[^;]*session\.upload_progress\.enabled\][[:space:]]*=[[:space:]]*(off|0)' /etc/php/*/fpm/pool.d/; then
  ok "Mitigación de CVE-2026-115560 en el pool de PHP"
else
  mal "Falta la mitigación de CVE-2026-115560 en el pool de PHP"
fi

echo
[ "$fallos" -eq 0 ] && echo "Todo correcto." || { echo "Comprobaciones fallidas: $fallos"; exit 1; }
