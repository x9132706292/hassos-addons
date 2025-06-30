# Redis Add-on for Home Assistant

![Redis Add-on Logo](https://github.com/x9132706292/hassos-addons/blob/main/hassio-addon-redis/logo.png)

## Description
This add-on provides a Redis server for Home Assistant, enabling fast in-memory data storage for integrations, scripts, and automations. Redis is a high-performance key-value store that can be used for caching, session management, or real-time data processing.

## Features
- Runs Redis server on port `6379`.
- Optional password protection for secure access.
- Persistent storage using Home Assistant's `/data` directory.
- Supports multiple architectures: `aarch64`, `amd64`, `armhf`, `armv7`, `i386`.

## Installation
1. Add this repository to Home Assistant:
   - Navigate to **Settings > Add-ons > Add-on Store**.
   - Click the three dots in the top right corner and select **Repositories**.
   - Add the URL: `https://github.com/x9132706292/hassos-addons`.
2. Find the **Redis** add-on in the Add-on Store and click **Install**.
3. Configure the add-on (e.g., set a password if needed).
4. Start the add-on.

## Configuration
| Option    | Description                          | Default |
|-----------|--------------------------------------|---------|
| `password`| Optional password for Redis access   | None    |

### Example Configuration
```yaml
password: "your_secure_password"
```

## Usage
- Connect to the Redis server using the IP address of your Home Assistant instance and port `6379`.
- Example command using `redis-cli`:
  ```bash
  redis-cli -h <HA_IP> -p 6379 -a <password>
  ```
- Use Redis in your Home Assistant integrations, such as Node-RED or custom scripts, for caching or data storage.

## Support
For issues, questions, or feature requests, please open an issue on the [GitHub repository](https://github.com/x9132706292/hassos-addons).

## License
MIT License
