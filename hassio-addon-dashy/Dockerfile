FROM lissy93/dashy:4.6.14

# Dashy ожидает данные в /app/user-data. 
# Мы перенаправляем это в постоянную директорию /data аддона Home Assistant.
RUN mkdir -p /data && \
    # Копируем конфиг по умолчанию только если он еще не существует (при первом запуске)
    cp -n /app/user-data/conf.yml /data/conf.yml 2>/dev/null || true && \
    # Гарантируем, что у пользователя node (UID 1000) есть права на запись в /data [[3]]
    chown -R 1000:1000 /data && \
    # Удаляем исходную папку и создаем символическую ссылку на /data
    rm -rf /app/user-data && \
    ln -s /data /app/user-data
