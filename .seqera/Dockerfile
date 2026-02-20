# IGV Web App Studio for Seqera Platform

# Add a default Connect client version. Can be overridden by build arg
ARG CONNECT_CLIENT_VERSION="0.9.0"
# Pin IGV webapp version (use "master" for latest dev build)
ARG IGV_WEBAPP_VERSION="v2.4.2"

# Stage 1: Build IGV webapp using Node.js
FROM node:18-slim AS igv-builder
ARG IGV_WEBAPP_VERSION
WORKDIR /build
RUN apt-get update && apt-get install -y curl unzip git \
    && curl -L -o igv-webapp.zip "https://github.com/igvteam/igv-webapp/archive/${IGV_WEBAPP_VERSION}.zip" \
    && unzip igv-webapp.zip \
    && mv igv-webapp-* igv-webapp \
    && cd igv-webapp \
    && npm install \
    && npm run build

# Stage 2: Connect client
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Stage 3: Final runtime image
FROM ubuntu:20.04

# Install nginx, curl, and jq for runtime
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    nginx \
    curl \
    jq \
    python3 \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Copy connect client from Seqera base image and install early
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Create directories for IGV webapp
RUN mkdir -p /opt/igv-webapp /opt/igv-webapp/js /etc/nginx/sites-enabled

# Copy built IGV webapp from builder stage
COPY --from=igv-builder /build/igv-webapp/dist/ /opt/igv-webapp/

# Copy nginx configuration template
COPY nginx.conf /etc/nginx/sites-available/igv-app

# Copy data discovery and config generation scripts
COPY discover-data-links.sh /usr/local/bin/discover-data-links.sh
COPY generate-igv-config.sh /usr/local/bin/generate-igv-config.sh
COPY igvwebConfig.template.js /opt/igv-webapp/js/igvwebConfig.template.js

# Copy example user config for documentation
COPY example-user-config.json /opt/igv-webapp/example-user-config.json

# Create startup script that uses dynamic port
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh \
    && chmod +x /usr/local/bin/discover-data-links.sh \
    && chmod +x /usr/local/bin/generate-igv-config.sh

# Remove default nginx configuration and create symlink
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/igv-app /etc/nginx/sites-enabled/default

# Healthcheck uses shell form so CONNECT_TOOL_PORT is resolved at runtime
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -sf http://localhost:${CONNECT_TOOL_PORT:-8080}/ || exit 1

# Use connect client as entrypoint with our startup script
# Note: Running as root is required for connect-client to set up loop devices for Fusion
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint", "/usr/local/bin/start.sh"]
