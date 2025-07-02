FROM ghcr.io/nextcloud-releases/all-in-one:latest

# Устанавливаем утилиты
RUN apk add --no-cache jq

COPY run.sh /run.sh
RUN chmod +x /run.sh


ENTRYPOINT ["/run.sh"]

HEALTHCHECK &{["CMD-SHELL" "/healthcheck.sh"] "0s" "0s" "0s" "0s" '\x00'}
