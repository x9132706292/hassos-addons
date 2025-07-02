FROM 

# Устанавливаем утилиты
RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /app/scripts/start.sh
RUN chmod +x /app/scripts/start.sh



# Health check
HEALTHCHECK CMD curl --fail http://127.0.0.1:3000 || exit 1
