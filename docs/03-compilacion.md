# Paso 3 de 7: Descarga y compilación

**Objetivo:** obtener los programas de Zabbix a partir del código oficial. La compilación tomó 62 segundos con 6 vCPU.

```mermaid
flowchart LR
    A["1. Requisitos"] --> B["2. Dependencias"] --> C["3. Compilación"]:::now --> D["4. Base de datos"] --> E["5. Servicios"] --> F["6. Frontend"] --> G["7. Verificación"]
    classDef now fill:#d40000,color:#fff
```

## 3.1 Descargar esta guía y el código

Los pasos siguientes usan los archivos de `config/` de este repositorio:

```bash
cd ~
git clone https://github.com/SimonLexRS/Zabbix-8-rc3-Instalacion.git

U=https://cdn.zabbix.com/zabbix/sources/release_candidates/8.0/zabbix-8.0.0rc3.tar.gz
curl -sSLO "$U"
curl -sSLO "$U.sha256"
```

## 3.2 Verificar que la descarga es auténtica

```bash
cat zabbix-8.0.0rc3.tar.gz.sha256
sha256sum zabbix-8.0.0rc3.tar.gz
```

**Los dos valores deben ser iguales:**

```text
2a2c16faf91d20e0464863498497c96ec42093d367bd6754d7f3602c3070ecce
```

> [!CAUTION]
> Si no coinciden, no continúes: borra el archivo y descárgalo otra vez.

## 3.3 Crear el usuario `zabbix`

Los servicios se ejecutan con este usuario, sin permisos de administrador y sin poder iniciar sesión:

```bash
sudo addgroup --system --quiet zabbix
sudo adduser --quiet --system --disabled-login --ingroup zabbix \
  --home /var/lib/zabbix --shell /usr/sbin/nologin zabbix
```

## 3.4 Compilar e instalar

```bash
tar xzf zabbix-8.0.0rc3.tar.gz
cd ~/zabbix-8.0.0rc3

./configure --prefix=/usr/local --sysconfdir=/etc/zabbix \
  --enable-server --enable-agent --enable-agent2 --enable-ipv6 \
  --with-postgresql --with-net-snmp --with-libcurl --with-libxml2 \
  --with-openssl --with-ssh --with-openipmi --with-unixodbc \
  --with-ldap --with-libpcre2 --with-ares

make -j"$(nproc)"
sudo make install
```

| Opción | Qué hace |
|---|---|
| `--prefix=/usr/local` | Instala los programas en `/usr/local` |
| `--sysconfdir=/etc/zabbix` | Guarda la configuración en `/etc/zabbix` |
| `--enable-server` | Compila el Zabbix server |
| `--enable-agent2` | Compila el agente 2 |
| `--enable-agent` | Compila `zabbix_get`, usado en la verificación, y el agente clásico, que aquí no se ejecuta |
| `--with-postgresql` | Usa PostgreSQL como base de datos |
| `--with-*` restantes | Activan SNMP, HTTP, TLS, SSH, IPMI, ODBC, LDAP, expresiones regulares y DNS asíncrono |

## ✅ Qué deberías ver

```bash
zabbix_server -V | head -1
zabbix_agent2 -V | head -1
ldd /usr/local/sbin/zabbix_server | grep -c 'not found'
```

```text
zabbix_server (Zabbix) 8.0.0rc3
zabbix_agent2 (Zabbix) 8.0.0rc3
0
```

El `0` significa que no falta ninguna librería.

> [!TIP]
> Conserva `~/zabbix-8.0.0rc3`: los pasos 4 y 6 usan archivos de ahí.

**¿Falló?** Revisa [errores de `configure`](problemas-y-soluciones.md#5-configure-se-detiene-con-un-error).

---

⬅️ [Paso 2](02-dependencias.md) | ➡️ Siguiente: [Paso 4: Base de datos](04-base-de-datos.md)
