# =============================================================================
# Stage 1: Builder
# =============================================================================
FROM node:14-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Install ONLY production dependencies in the builder stage
RUN npm ci --only=production

# Copy the rest of the application source code
COPY . .

# =============================================================================
# Stage 2: Production Runner
# =============================================================================
FROM node:14-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production \
    PORT=3000

# Copy the production-ready node_modules from the builder
COPY --from=builder --chown=node:node /app/node_modules ./node_modules

# Copy your actual application files (src, views, public, etc.)
# Because of the .dockerignore file, this won't copy local junk.
COPY --from=builder --chown=node:node /app .

USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/ || exit 1

CMD ["node", "src/index.js"]
