#!/usr/bin/env bash
# Revisa el server antes de instalar y recomienda el método. Solo lee: no cambia nada.
set -u

case "$(uname -m)" in
  x86_64)  arch="AMD64 / x64" ;;
  aarch64) arch="ARM64" ;;
  *)       arch="no cubierta por esta guía ($(uname -m))" ;;
esac

. /etc/os-release
ram_mib=$(free -m | awk '/^Mem:/ {print $2}')
disk_gib=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')

echo "Arquitectura : $arch"
echo "Sistema      : ${PRETTY_NAME:-desconocido}"
echo "CPU          : $(nproc) vCPU"
echo "RAM          : ${ram_mib} MiB"
echo "Disco libre  : ${disk_gib} GiB"

[ "$ram_mib" -lt 8192 ] && echo "Aviso        : menos de 8 GiB de RAM, el ejemplo de Zabbix para 1 000 métricas"

ocupados=$(ss -tln | awk '{print $4}' | grep -E ':(80|5432|10050|10051)$' | sed 's/.*://' | sort -un | tr '\n' ' ')
echo "Puertos en uso: ${ocupados:-ninguno de 80, 5432, 10050 y 10051}"

case "${VERSION_ID:-}" in
  26.04) php_min="8.5.4-0ubuntu1.5" ;;
  26.10) php_min="8.5.9-0ubuntu2.1" ;;
  *)     php_min="" ;;
esac
php_cand=$(apt-cache policy php8.5-fpm 2>/dev/null | awk '/Candidate:/ {print $2}')
if [ -n "$php_min" ] && [ -n "$php_cand" ] && [ "$php_cand" != "(none)" ]; then
  if dpkg --compare-versions "$php_cand" ge "$php_min"; then
    echo "PHP          : $php_cand, con el parche de CVE-2026-109618 y 109619"
  else
    echo "PHP          : $php_cand, SIN el parche. Ejecuta apt-get update (docs/seguridad-php.md)"
  fi
fi

case "${ID:-}-${VERSION_ID:-}" in
  ubuntu-26.04) echo "Método       : paquetes oficiales (docs/alternativa-paquetes-26.04.md)" ;;
  ubuntu-26.10) echo "Método       : compilar desde fuente (docs/01-requisitos.md)" ;;
  *)            echo "Método       : sistema no cubierto por esta guía" ;;
esac
