FROM ghcr.io/nextcloud-releases/all-in-one:latest

# Устанавливаем утилиты
RUN apk --update add jq 

COPY run.sh /run.sh
RUN chmod +x /run.sh
