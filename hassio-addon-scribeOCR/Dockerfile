# ===== Stage 1: Clone and prepare source =====
FROM node:20-alpine AS builder

# Install git
RUN apk add --no-cache git

WORKDIR /build

# Аргументы для гибкости (по умолчанию — master)
ARG REPO_URL=https://github.com/scribeocr/scribeocr.git
ARG BRANCH=master

# Клонирование с сабмодулями
# --recurse-submodules автоматически инициализирует подмодули
RUN git clone --depth 1 --branch ${BRANCH} --recurse-submodules ${REPO_URL} source && \
    cd source && \
    git submodule update --init --recursive

WORKDIR /build/source

# Установка зависимостей
COPY package*.json ./
RUN npm ci --include=dev --omit=optional

# ===== Stage 2: Production runtime =====
FROM node:20-alpine

# Установка http-server и wget для healthcheck
RUN apk add --no-cache wget && \
    npm install -g http-server

WORKDIR /app

# Копирование приложения из builder
COPY --from=builder /build/source ./

# Безопасность: запуск от non-root пользователя
RUN chown -R node:node /app && \
    apk del git && \
    npm cache clean --force && \
    rm -rf /tmp/* /var/cache/apk/*
USER node

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Запуск
CMD ["http-server", ".", "-p", "8080", "-a", "0.0.0.0", "--cors", "--silent"]
