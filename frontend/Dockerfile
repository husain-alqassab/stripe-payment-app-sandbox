# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files and install
COPY package.json ./
RUN npm install

# Copy source and build
COPY . .
RUN npm run build

# Production stage - Use Red Hat UBI nginx
FROM registry.access.redhat.com/ubi8/nginx-120:latest

# Temporarily switch to root to set up files
USER 0

# Copy nginx config to the correct location for UBI nginx
# UBI nginx reads configs from /opt/app-root/etc/nginx.d/
COPY nginx.conf /opt/app-root/etc/nginx.d/default.conf

# Copy built React app
COPY --from=build /app/build /opt/app-root/src

# Set OpenShift-compatible permissions
# Group 0 (root group) gets same permissions as owner
RUN chown -R 1001:0 /opt/app-root/src && \
    chmod -R g=u /opt/app-root/src && \
    chown -R 1001:0 /opt/app-root/etc && \
    chmod -R g=u /opt/app-root/etc

# Switch to non-root user
USER 1001

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
