FROM lissy93/dashy:4.6.14

# Переключаемся на root для установки пакетов и настройки
USER root

# Устанавливаем su-exec (может отсутствовать в базовом образе)
RUN apk add --no-cache su-exec

# Копируем скрипт запуска и делаем его исполняемым
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Переопределяем точку входа на наш скрипт
ENTRYPOINT ["/run.sh"]
