FROM ghcr.io/nextcloud-releases/all-in-one:latest

# Устанавливаем утилиты
RUN apk --update add jq 

ADD /start.sh /run.sh
COPY start.sh /start.sh
RUN chmod +x /start.sh

