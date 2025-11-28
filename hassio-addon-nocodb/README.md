# NocoDB Home Assistant Add-on
<h1 align="center" style="border-bottom: none">
    <div>
        <a style="color:#36f" href="https://www.nocodb.com">
            <img src="https://github.com/x9132706292/hassos-addons/blob/main/hassio-addon-nocodb/logo.png" height="80" />
            <br>
    The Open Source Airtable Alternative 
        </a>
        <br>
    </div>
</h1>

## Description
This repository provides a Home Assistant add-on for [NocoDB](https://www.nocodb.com/), an open-source Airtable alternative that transforms any database into a smart spreadsheet. The NocoDB add-on enables Home Assistant users to manage databases within their Home Assistant environment, offering a user-friendly interface for organizing and visualizing data.

Key features include:
- Creating and managing databases with a spreadsheet-like interface.
- Connecting to a PostgreSQL database (default configuration) or other supported databases via NocoDB.
- Integrating NocoDB data with Home Assistant automations and dashboards.
- Accessing data through a web-based UI or REST/GraphQL APIs.
- Automatic startup with Home Assistant for seamless operation.

This add-on runs as a Docker container, managed via the Home Assistant Supervisor, and supports multiple architectures (`aarch64`, `amd64`, `armhf`, `armv7`, `i386`).

## Features
- **Easy Installation**: Install and configure directly from the Home Assistant Add-on Store.
- **PostgreSQL Support**: Configured to connect to a PostgreSQL database by default, with customizable connection settings.
- **API Integration**: Use NocoDB’s REST or GraphQL APIs for automation and data access.
- **Home Assistant Compatibility**: Leverage NocoDB data in Home Assistant scripts, automations, or dashboards.
- **Network Configuration**: Exposes port `8080` for web access, with a configurable public URL.

## Installation
1. Add this repository to Home Assistant:
   - Navigate to **Settings > Add-ons > Add-on Store**.
   - Click the three dots in the top-right corner and select **Repositories**.
   - Add the repository URL: `https://github.com/x9132706292/hassos-addons`.
2. Find and install the **NocoDB** add-on from the Add-on Store.
3. Configure the add-on settings via the **Configuration** tab.
4. Start the add-on and access the NocoDB web interface through the provided URL or Home Assistant sidebar.

## Configuration
The add-on supports the following configuration options (as defined in `config.yaml`):
- `POSTGRES_HOST`: Hostname of the PostgreSQL database (default: `77b2833f-timescaledb`).
- `POSTGRES_PORT`: Port for the PostgreSQL database (default: `5432`, range: 1–65534).
- `POSTGRES_DB`: Database name for NocoDB (default: `nocodb`).
- `POSTGRES_USER`: Username for PostgreSQL access (default: `nocodb`).
- `POSTGRES_PASSWORD`: Password for PostgreSQL access (default: `nocodb`).
- `NC_PUBLIC_URL`: Public URL for accessing the NocoDB interface (default: `http://127.0.0.1:8080`).

Example configuration:
```yaml
POSTGRES_HOST: "77b2833f-timescaledb"
POSTGRES_PORT: 5432
POSTGRES_DB: "nocodb"
POSTGRES_USER: "nocodb"
POSTGRES_PASSWORD: "your_secure_password"
NC_PUBLIC_URL: "http://127.0.0.1:8080"
```

## Usage
- Access the NocoDB web interface via the URL specified in `NC_PUBLIC_URL` (e.g., `http://<your-ha-instance>:8080`).
- Create and manage tables, views (Grid, Kanban, Gallery, etc.), and data entries.
- Use NocoDB’s APIs to integrate with Home Assistant automations or scripts.
- Display NocoDB data in Home Assistant dashboards using RESTful sensors or custom cards.

## Requirements
- Home Assistant with Supervisor installed.
- A running PostgreSQL database accessible by the add-on (e.g., via the `timescaledb` add-on or an external database).
- Network access to the configured `POSTGRES_HOST` and `POSTGRES_PORT`.

## Support
- Report issues or request features on the GitHub repository: [https://github.com/x9132706292/hassos-addons](https://github.com/x9132706292/hassos-addons).
- Refer to the [NocoDB documentation](https://docs.nocodb.com/) for detailed usage instructions.
- Seek community help at the [Home Assistant Community Forum](https://community.home-assistant.io/).

## Contributing
Contributions are welcome! Submit pull requests or suggest improvements via GitHub issues.

## License
This add-on is licensed under the [MIT License](LICENSE).
