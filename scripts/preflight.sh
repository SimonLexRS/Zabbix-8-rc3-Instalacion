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

case "${ID:-}-${VERSION_ID:-}" in
  ubuntu-26.04) echo "Método       : paquetes oficiales (docs/alternativa-paquetes-26.04.md)" ;;
  ubuntu-26.10) echo "Método       : compilar desde fuente (docs/01-requisitos.md)" ;;
  *)            echo "Método       : sistema no cubierto por esta guía" ;;
esac
