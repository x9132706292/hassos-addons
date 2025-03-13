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
   - Supports MySQL/MariaDB, PostgreSQL, SQLite, or Oracle. Recommended versions:
      - **MySQL**: 8.0 / 8.4
      - **MariaDB**: 10.6 / 10.11 (recommended) / 11.4
      - **PostgreSQL**: 13 / 14 / 15 / 16 / 17
      - **Oracle**: 11g / 18 / 21 / 23 (Enterprise only)
      - **SQLite**: 3.24+ (for testing/minimal instances)
   - For PostgreSQL example (e.g., with [TimescaleDB add-on](https://github.com/expaso/hassos-addon-timescaledb)):
   ``` bash
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
4. **Configure the Add-on:**
   - Edit the configuration in Home Assistant:
   ``` yaml
   trusted_domains:
     - "localhost"
     - "nc.example.com"
   admin_user: "admin"
   admin_password: "nextcloud"
   db_type: "pgsql"
   db_host: "77b2833f-timescaledb"
   db_port: "5432"
   db_name: "nextcloud"
   db_user: "nextcloud"
   db_password: "your_secure_password"
   data_dir: "/share/nextcloud"
   ```
   - Replace values as needed.
  
5. **Start the Add-on:**
   - Click `Start` and check the logs:
   ``` txt
   [INFO] Automated installation completed successfully.
   ```

6. **Verify:**
   Open `http://<ip>:8080` or use the "Open Web UI" button.
   Log in with `admin_user` and `admin_password`.
    
## Configuration
Option | Description	| Default |
| --- | --- | ---|
| `trusted_domains` | List of trusted domains for Nextcloud access | `["localhost"]` |
| `admin_user` | Admin username for initial setup | `admin` |
| `admin_password` | Admin password for initial setup | `nextcloud` |
| `db_type` | Database type (mysql, pgsql, sqlite, oci) | `pgsql` |
| `db_host` | Database host address | `77b2833f-timescaledb` |
| `db_port` | Database port | `5432` |
| `db_name` | Database name | `nextcloud` |
| `db_user` | Database username | `nextcloud` |
| `db_password` | Database password | `your_secure_password` |
| `data_dir` | Directory for Nextcloud data | `/share/nextcloud` |

- The add-on appends <container_ip>:8080 to trusted_domains.

## Notes
- **Data Directory:** Ensure `data_dir` exists and has correct permissions (`33:33`) before starting:
``` bash
sudo mkdir -p /share/nextcloud
sudo chown -R 33:33 /share/nextcloud
sudo chmod -R 770 /share/nextcloud
```
## Troubleshooting
   - **Installation Fails:**
      - Check logs for database connection errors.
      - Verify `db_type`, `db_host`, `db_port`, `db_user`, and `db_password`.
   - **Config Not Found:**
      - Ensure `<data_dir>/config/config.php` exists (`ls -l <data_dir>/config`).
## Credits
   - Built on [Nextcloud Docker image](https://hub.docker.com/_/nextcloud).
## License
MIT License. See [LICENSE] for details.
