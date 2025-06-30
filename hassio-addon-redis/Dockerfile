ARG BUILD_FROM
FROM $BUILD_FROM

# Установка Redis
RUN apk add --no-cache redis

# Copy s6 service configuration
COPY rootfs /

# Set up s6-overlay service
COPY run.sh /etc/services.d/redis/run
RUN chmod a+x /etc/services.d/redis/run
