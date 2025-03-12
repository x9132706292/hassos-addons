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
```
``` sql
CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH PASSWORD 'your_secure_password';
ALTER DATABASE nextcloud OWNER TO nextcloud;
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
\c nextcloud
GRANT ALL ON SCHEMA public TO nextcloud;
\q
```
4. **Start the Add-on:**
Go to the "Nextcloud" add-on page and click Start.
Check the logs for:
```txt
[INFO] No config found. Please complete the setup via the web interface at http://<ip>:8080
```
5. **Complete Setup:**
- Go to the "Nextcloud" add-on page and click `Open Web UI` (this opens `http://<hassio_ip>:8080`).
- In the Nextcloud setup wizard:
   - Set an admin username and password.
   - Choose "PostgreSQL" as the database.
   - Enter:
      - Database user: `nextcloud`
      - Database password: `your_secure_password`
      - Database name: `nextcloud`
      - Database host: `77b2833f-timescaledb:5432` (if using TimescaleDB add-on) or your DB host
   - Set data directory to `/share/nextcloud` (manually enter this path).
   - Click "Finish setup".
6. **Verify:**
- Restart the add-on and check the logs:
``` text
[INFO] Nextcloud config found, updating trusted domains if necessary...
[INFO] Trusted domains updated successfully.
```
- Access Nextcloud via `Open Web UI`.
 
## Configuration
Option | Description	| Default |
| --- | --- | ---|
| trusted_domains	| Custom domain for Nextcloud access (e.g., your.domain.com) | localhost |

- Edit this in the add-on configuration UI.
- The add-on automatically adds `<container_ip>:8080` to trusted domains.

## Notes
- **Data Directory:** The add-on uses `/share/nextcloud` as the data directory. You must manually specify this path during the initial setup in the web interface.
- **Database Cleanup:** If you reinstall the add-on, you may need to manually clean the database to avoid conflicts:
``` bash
psql -h <db_host> -U postgres
```
``` sql
DROP DATABASE nextcloud;
```
Then recreate it as described in step 3.
- **TimescaleDB:** For a compatible PostgreSQL database, consider using the [TimescaleDB](https://github.com/hassio-addons/addon-timescaledb) add-on with host `77b2833f-timescaledb:5432`.

## License
MIT License. See [LICENSE] for details.
