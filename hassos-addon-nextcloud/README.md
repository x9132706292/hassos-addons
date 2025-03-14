# Nextcloud add-on for Home Assistant

![logo](https://raw.githubusercontent.com/enricodeleo/hassio-addon-nextcloud/master/logo.png)

## About

This is a Home Assistant OS (HassOS) add-on that deploys a [Nextcloud](https://nextcloud.com/) instance, allowing you to run a personal cloud storage solution alongside your Home Assistant setup.

## Features
- Runs Nextcloud in a Docker container.
- Persistent data storage in `/share/nextcloud`.
- Supports PostgreSQL as the database backend.
- Works with manual installation via the Nextcloud web interface.

## Prerequisites
- Home Assistant OS installed and running.
- A PostgreSQL database instance (e.g., the [TimescaleDB add-on](https://github.com/expaso/hassos-addon-timescaledb) or an external PostgreSQL server).
- Basic knowledge of Docker and database setup.

## Installation

### Step 1: Add the Repository
   1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**.
   2. Click the three-dot menu in the top-right corner and select **Repositories**.
   3. Add the following URL:
      ``` txt
      https://github.com/x9132706292/hassos-addons
      ```
   4. Click **Add** and wait for the repository to load.

### Step 2: Install the Add-on
   1. Find **Nextcloud Add-on** in the Add-on Store.
   2. Click **Install** and wait for the installation to complete.

### Step 3: Prepare the Database
   1. Set up a PostgreSQL database (e.g., using the [TimescaleDB add-on](https://github.com/expaso/hassos-addon-timescaledb) or an external server).
   2. Create a database and user for Nextcloud:
   ```sql
   CREATE DATABASE nextcloud;
   CREATE USER nextcloud WITH PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
   ```
   3. Note the database host (e.g., `77b2833f-timescaledb`), port (default `5432`), database name (`nextcloud`), username (`nextcloud`), and password.

### Step 4: Start the Add-on
   1. In the add-on configuration, leave the settings empty (no configuration is required).
   2. Click Start to launch the add-on.
   3. Check the add-on logs to ensure it starts without errors.

### Step 5: Complete Installation via Web Interface
   1. Open your browser and go to `http://<your-ha-ip>:8080` (replace `<your-ha-ip>` with your Home Assistant IP).
   2. Follow the Nextcloud web installation wizard:
      - Set the admin username (e.g., `admin`) and password.
      - Configure the database:
         - **Database type:** PostgreSQL
         - **Database user:** `nextcloud`
         - **Database password:** `your_secure_password`
         - **Database name:** `nextcloud`
         - **Database host:** `77b2833f-timescaledb` (or your PostgreSQL host)
      - Click **Finish setup**.
   3. Wait for the installation to complete.

### Step 6: (Optional) Customize `config.php`
   - The configuration file is located at `/share/nextcloud/html/config/config.php`.
   - To edit it:
      1. Access the file via SSH or the Home Assistant file editor.
      2. Example adjustments:
         - Add trusted domains:
      ``` php
      'trusted_domains' => 
        array (
          0 => 'localhost',
          1 => '172.30.33.8:8080', // Replace with your HA IP and port
        ),
      ```
        - Set `config_is_read_only` to `true` if desired:
        ``` php
           'config_is_read_only' => true,
        ```
     3. Save the changes.

### Step 7: Verify Persistence
   - Restart the add-on to ensure settings persist.
   - Uninstall and reinstall the add-on to confirm that data in `/share/nextcloud` remains intact.

### Notes
   - The add-on uses `/share/nextcloud` for data storage and `/share/nextcloud/html/config` for configuration.
   - Ensure the PostgreSQL server is accessible from the add-on (check network settings if using an external DB).
   - Logs are available in the Home Assistant add-on interface for troubleshooting.

### Troubleshooting
   - **Web interface not loading:** Check the add-on logs for errors and ensure port `8080` is not blocked.
   - **Database connection issues:** Verify the database host, port, username, and password.
   - **Config not persisting:** Ensure `/share/nextcloud` has correct permissions (`chown 33:33 /share/nextcloud` and `chmod 770 /share/nextcloud`).

### Contributing
Feel free to submit issues or pull requests to improve this add-on!

### License
This project is licensed under the MIT License.
