#!/bin/bash

# IGV Studio startup script for Seqera Platform
set -e

echo "Starting IGV Web App Studio..."
echo "Using port: ${CONNECT_TOOL_PORT}"

# Check if CONNECT_TOOL_PORT is set
if [ -z "$CONNECT_TOOL_PORT" ]; then
    echo "Error: CONNECT_TOOL_PORT environment variable is not set"
    exit 1
fi

# Wait for Fusion data directory to be populated (with timeout)
echo "Waiting for Fusion data mounts..."
WAIT_TIMEOUT=60
WAITED=0
while [ ! -d "/workspace/data" ] || [ -z "$(ls -A /workspace/data 2>/dev/null)" ]; do
    if [ $WAITED -ge $WAIT_TIMEOUT ]; then
        echo "No data links mounted after ${WAIT_TIMEOUT}s, using default config"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo "Waiting for data... (${WAITED}s)"
done

# Run discovery only if data directory has content
if [ -d "/workspace/data" ] && [ -n "$(ls -A /workspace/data 2>/dev/null)" ]; then
    echo "Found data in /workspace/data, running discovery..."
    ls -la /workspace/data/
    /usr/local/bin/discover-data-links.sh
    /usr/local/bin/generate-igv-config.sh
    echo "IGV configuration updated with discovered data"
else
    echo "No Fusion data links found, using default configuration"
    cp /opt/igv-webapp/js/igvwebConfig.template.js /opt/igv-webapp/js/igvwebConfig.js
fi

# Create nginx configuration with dynamic port
sed -i "s/CONNECT_TOOL_PORT_PLACEHOLDER/${CONNECT_TOOL_PORT}/g" /etc/nginx/sites-available/igv-app

# Test nginx configuration
nginx -t

# Start nginx in foreground mode
echo "Starting nginx on port ${CONNECT_TOOL_PORT}"
echo "IGV Web App will be available at the Studio URL"

# Handle SIGTERM gracefully
trap 'echo "Shutting down nginx..."; nginx -s quit; exit 0' SIGTERM

# Start nginx
exec nginx -g 'daemon off;'