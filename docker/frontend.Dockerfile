# Build stage
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files
COPY packages/frontend/package*.json ./
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY packages/frontend ./

# Build the application
RUN npm run build

# Runtime stage
FROM nginx:alpine

# Copy custom nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Copy environment template
COPY docker/env.template /etc/nginx/templates/

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]