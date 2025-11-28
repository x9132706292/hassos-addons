# [Teable](https://teablr.io) Add-on for Home Assistant

![Teable Logo](https://raw.githubusercontent.com/x9132706292/hassos-addons/refs/heads/main/hassio-addon-teable/logo.png)

The Teable Add-on for Home Assistant provides a powerful, spreadsheet-like database solution to manage and organize your smart home data efficiently. It allows users to create, customize, and query tables with a user-friendly interface, seamlessly integrating with Home Assistant for enhanced automation and data visualization.

## Features
- **Flexible Data Management**: Create and manage tables with customizable fields to store and organize your Home Assistant data.
- **Seamless Integration**: Easily connect Teable with Home Assistant to leverage your smart home data for automations, dashboards, or analytics.
- **Web-Based Interface**: Access and manage your database through a clean, intuitive web interface.
- **Scalable and Performant**: Built to handle large datasets with fast querying and real-time updates.

## Dependencies
This add-on is designed to work with the following Home Assistant add-ons for optimal performance:
- **[Redis Add-on](https://github.com/x9132706292/hassos-addons/tree/main/hassio-addon-redis)**: Provides a high-performance in-memory data store for caching and session management.
- **[TimescaleDB Add-on](https://github.com/expaso/hassos-addon-timescaledb)**: Offers a time-series database optimized for handling large volumes of time-stamped data, ideal for IoT and smart home applications.

Alternatively, you can use independently installed [Redis](https://redis.io/) or [TimescaleDB](https://www.timescale.com/) servers by configuring the add-on to connect to your external instances. Ensure proper network access and credentials are provided in the add-on configuration for seamless integration.

## Installation
1. Add the repository `https://github.com/x9132706292/hassos-addons` to your Home Assistant Add-on Store.
2. Install the Teable Add-on.
3. (Optional) Install the [Redis Add-on](https://github.com/x9132706292/hassos-addons/tree/main/hassio-addon-redis) and [TimescaleDB Add-on](https://github.com/expaso/hassos-addon-timescaledb) from their respective repositories, or configure connections to external Redis and TimescaleDB servers.
4. Configure the add-on settings via the Home Assistant Add-on panel.
5. Start the add-on and access the Teable interface through the provided web URL.

## Configuration
- **Database Connection**: Specify the connection details for Redis and TimescaleDB (either via add-ons or external servers).
- **Port Settings**: Ensure the web interface port is correctly set and not conflicting with other services.
- **Authentication**: Configure any necessary credentials for secure access to the Teable interface.

## Notes
- For advanced users, external Redis or TimescaleDB servers can be used to offload processing or integrate with existing infrastructure.
- Regularly-EU Regularly back up your database to prevent data loss, especially when using external servers.

For more details, refer to the official repository: [Teable Add-on](https://github.com/x9132706292/hassos-addons/tree/main/hassio-addon-teable).
