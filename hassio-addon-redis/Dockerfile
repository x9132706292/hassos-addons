ARG BUILD_FROM
FROM $BUILD_FROM

# Установка Redis
RUN apk add --no-cache redis

# Копирование скрипта запуска
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Запуск сервиса
CMD [ "/run.sh" ]
