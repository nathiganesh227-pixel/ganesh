# Multi-stage Dockerfile for PLAZA NestJS Production/Staging API
# Stage 1: Build & Prune
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Install build dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and config
COPY tsconfig*.json nest-cli.json ./
COPY src/ ./src/

# Compile TypeScript
RUN npm run build

# Prune devDependencies for production image
RUN npm prune --production

# Stage 2: Minimal Production Runtime
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

ENV NODE_ENV=production
ENV PORT=3000

# Security: run as unprivileged node user
USER node

# Copy production artifacts
COPY --chown=node:node --from=builder /usr/src/app/package*.json ./
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=builder /usr/src/app/dist ./dist

EXPOSE 3000

# Health check probe against /api/v1/health
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3000/api/v1/health || exit 1

CMD ["node", "dist/main.js"]
