# Alternativa: paquetes oficiales en Ubuntu 26.04

**Para quién:** servidores **ARM64 o AMD64/x64 con Ubuntu 26.04**. Es la ruta más simple: no hay que compilar, y las actualizaciones llegan por `apt`.

> [!WARNING]
> **Esta ruta no se ejecutó en la instalación real de esta guía.** Se armó a partir de los índices y del contenido de los paquetes RC3 oficiales. Si algo no coincide, revisa la [documentación oficial](https://www.zabbix.com/documentation/8.0/en/manual/installation/install_from_packages/debian_ubuntu).

```mermaid
flowchart LR
    A["Agregar repositorio"] --> B["Instalar paquetes"] --> C["Crear base de datos"] --> D["Configurar"] --> E["Arrancar"] --> F["Verificar"]
```

## 1. Agregar el repositorio de Zabbix

El mismo archivo sirve para ambas arquitecturas: `apt` elige los paquetes correctos.

```bash
cd /tmp
curl -sSLO 'https://repo.zabbix.com/zabbix/8.0/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_8.0+ubuntu26.04_all.deb'
sudo apt-get install -y ./zabbix-release_latest_8.0+ubuntu26.04_all.deb
sudo apt-get update
```

Este paquete también activa `zabbix-unstable.sources`, el repositorio donde se publican los RC. Comprueba qué versión se instalará:

```bash
apt-cache policy zabbix-server-pgsql | head -3
```

Debe mostrar como candidata `8.0.0~rc3-1+ubuntu26.04`, o una posterior si Zabbix ya publicó otra.

## 2. Instalar

```bash
sudo apt-get install -y postgresql php-pgsql zabbix-server-pgsql zabbix-frontend-php \
  zabbix-nginx-conf zabbix-sql-scripts zabbix-agent2 zabbix-get
```

## 3. Crear la base de datos

```bash
sudo install -d -o root -g root -m 700 /root/.zabbix
PW=$(openssl rand -base64 33 | tr -d '/+=' | cut -c1-32)
printf '%s' "$PW" | sudo install -m 600 /dev/stdin /root/.zabbix/db_password

printf "CREATE ROLE zabbix LOGIN PASSWORD '%s';\n" "$PW" \
  | sudo -u postgres psql -q -v ON_ERROR_STOP=1
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix

zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz \
  | sudo -u zabbix psql -q -v ON_ERROR_STOP=1 -d zabbix
```

## 4. Configurar

```bash
PW=$(sudo cat /root/.zabbix/db_password)
sudo sed -i -E "s|^#? *DBPassword=.*|DBPassword=$PW|" /etc/zabbix/zabbix_server.conf
sudo sed -i -E 's|^#? *DBHost=.*|DBHost=localhost|' /etc/zabbix/zabbix_server.conf
```

El paquete enlaza su sitio en `/etc/nginx/conf.d/zabbix.conf`, con `listen` comentado. Actívalo en el puerto 80 y quita el sitio por defecto:

```bash
sudo sed -i -E 's|^# *listen +8080;|        listen 80;|' /etc/zabbix/nginx.conf
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
```

## 5. Arrancar

```bash
sudo systemctl restart zabbix-server zabbix-agent2 nginx php8.5-fpm
sudo systemctl enable zabbix-server zabbix-agent2 nginx php8.5-fpm
```

Abre `http://<IP-de-tu-server>/`. A diferencia de la compilación, aquí el **asistente web** crea la configuración del frontend: elige PostgreSQL, usuario `zabbix` y la contraseña de `/root/.zabbix/db_password`. Luego entra con `Admin` / `zabbix` y cámbiala de inmediato.

## 6. Verificar

```bash
scripts/verificar.sh
```

---

🛠️ [Problemas y soluciones](problemas-y-soluciones.md) | 🏠 [Inicio](../README.md)
