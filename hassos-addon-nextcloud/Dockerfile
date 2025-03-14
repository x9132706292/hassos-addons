FROM nextcloud:31.0.0

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    bash \
    jq \
    sudo \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Change the root folder for Nextcloud to the /share directory to be persistent
RUN  sed -i "s|/var/www|/share/nextcloud|g" /etc/apache2/sites-enabled/000-default.conf \
  && sed -i "s|/var/www|/share/nextcloud|g" /etc/apache2/apache2.conf \
  && sed -i "s|/var/www/html|/share/nextcloud/html|g" /entrypoint.sh \
  && sed -i "s|/var/www/html|/share/nextcloud/html|g" /usr/src/nextcloud/config/autoconfig.php

RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/fqdn.conf && a2enconf fqdn
   

# Копируем скрипт запуска
COPY init /
RUN chmod a+x /init

ENTRYPOINT [ "/init" ]
CMD ["apache2-foreground"]
