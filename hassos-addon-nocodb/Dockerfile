FROM nocodb/nocodb:latest

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Копируем скрипт запуска
COPY init /
RUN chmod a+x /init

ENTRYPOINT [ "/init" ]

# Start Nocodb
CMD ["/usr/src/appEntry/start.sh"]
