# Используем официальный образ teable как базовый
FROM ghcr.io/teableio/teable:latest

# Устанавливаем переменные окружения
ENV NEXT_ENV_IMAGES_ALL_REMOTE=true

# Копируем файл .env (предполагается, что он есть в директории сборки)
COPY .env /app/.env

# Указываем порт, который будет открыт
EXPOSE ${PORT}

# Настраиваем том для данных
VOLUME /app/.assets

# Команда для запуска приложения (по умолчанию наследуется из базового образа)
# Если требуется что-то специфическое, можно указать явно, например:
# CMD ["npm", "start"]

# Настройка healthcheck
HEALTHCHECK --start-period=5s --interval=5s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:${PORT}/health || exit 1
