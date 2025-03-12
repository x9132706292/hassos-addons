# Nextcloud add-on for Home Assistant

![logo](https://raw.githubusercontent.com/enricodeleo/hassio-addon-nextcloud/master/logo.png)

## About

This is a Home Assistant add-on that integrates [Nextcloud](https://nextcloud.com/), a self-hosted file sync and collaboration platform. With this add-on, you can access and manage your files, calendars, contacts, and more directly from your Home Assistant instance.

## Features
- **Web Interface**: Complete the initial setup via the Nextcloud web interface using the "Open Web UI" button.
- **Trusted Domains**: Automatically configures trusted domains, including your custom domain and container IP.
- **Persistent Data**: Stores Nextcloud data in `/share/nextcloud` for easy backups.

## Installation

1. **Add the Repository**:
   - In Home Assistant, go to `Settings` → `Add-ons` → `Add-on Store`.
   - Click the three-dot menu, select `Repositories`, and add:
```txt
https://github.com/x9132706292/hassos-addons
```
- Click `Add`.

2. **Install the Add-on**:
- Find "Nextcloud" in the Add-on Store and click `Install`.
- Wait for the installation to complete.

3. **Configure the Database**:
- This add-on uses PostgreSQL. You can use the [TimescaleDB add-on](https://github.com/hassio-addons/addon-timescaledb) with host `77b2833f-timescaledb:5432`.
- Set up a database beforehand:
```bash
psql -h <db_host> -U postgres
CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH PASSWORD 'your_secure_password';
ALTER DATABASE nextcloud OWNER TO nextcloud;
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
\c nextcloud
GRANT ALL ON SCHEMA public TO nextcloud;
\q
```
