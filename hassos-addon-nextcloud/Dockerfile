FROM nextcloud:latest

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    bash \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Указываем точку входа
CMD []
