# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Production stage - Use UBI (Universal Base Image) for better OpenShift compatibility
FROM registry.access.redhat.com/ubi8/nginx-120:latest

# Switch to root temporarily to copy files and set permissions
USER 0

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built files from build stage
COPY --from=build /app/build /opt/app-root/src

# Set proper permissions for OpenShift
RUN chown -R 1001:0 /opt/app-root/src && \
    chmod -R g=u /opt/app-root/src && \
    chown -R 1001:0 /var/log/nginx && \
    chmod -R g=u /var/log/nginx && \
    chown -R 1001:0 /var/lib/nginx && \
    chmod -R g=u /var/lib/nginx && \
    chown -R 1001:0 /etc/nginx && \
    chmod -R g=u /etc/nginx && \
    chown -R 1001:0 /run && \
    chmod -R g=u /run

# Switch back to non-root user (OpenShift will assign random UID in this range)
USER 1001

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
