# ===== Stage 1: Clone and prepare source =====
FROM node:20-alpine AS builder

# Install git and clean up cache
RUN apk add --no-cache git

WORKDIR /build

# Клонирование репозитория с сабмодулями
# Можно заменить ветку/тег через --branch <name>
ARG REPO_URL=https://github.com/scribeocr/scribeocr.git
ARG BRANCH=main

RUN git clone --depth 1 --branch ${BRANCH} --recurse-submodules ${REPO_URL} source && \
    cd source && \
    git submodule update --init --recursive

WORKDIR /build/source

# Установка зависимостей
COPY package*.json ./
RUN npm ci --include=dev --omit=optional

# ===== Stage 2: Production runtime =====
FROM node:20-alpine

# Установка http-server и утилит для healthcheck
RUN apk add --no-cache wget && \
    npm install -g http-server

WORKDIR /app

# Копирование готового приложения из builder
COPY --from=builder /build/source ./

# Права доступа (опционально, для безопасности)
RUN chown -R node:node /app
USER node

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Запуск сервера
# -a 0.0.0.0 — слушать все интерфейсы, --cors — разрешить CORS
CMD ["http-server", ".", "-p", "8080", "-a", "0.0.0.0", "--cors", "--silent"]
