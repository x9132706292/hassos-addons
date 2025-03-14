FROM nextcloud:latest

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    bash \
    jq \
    sudo \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Копируем скрипт запуска
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Указываем точку входа
ENTRYPOINT ["/run.sh"]
