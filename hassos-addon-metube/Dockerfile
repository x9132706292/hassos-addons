# Используем официальный образ MeTube как базовый
# Важно: нужно адаптировать под требования Home Assistant

FROM ghcr.io/alexta69/metube:latest

# Метки для Home Assistant Supervisor
LABEL \
  io.hass.version="2026.06.0" \
  io.hass.type="app" \
  io.hass.arch="amd64|aarch64|armv7"

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Создаём точку монтирования для загрузок
VOLUME ["/downloads"]

# Экспортируем порт
EXPOSE 8081

# Healthcheck для Supervisor
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS "http://localhost:8081/" || exit 1

# Entrypoint остаётся от оригинального образа
# Он уже обрабатывает переменные окружения PUID/PGID
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "./docker-entrypoint.sh"]
