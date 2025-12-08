#!/bin/bash

# IGV Studio startup script - Standalone version
set -e

# Use default port for standalone version
CONNECT_TOOL_PORT="${PORT:-8080}"

echo "Starting IGV Web App Studio (Standalone)..."
echo "Using port: ${CONNECT_TOOL_PORT}"

# Run Fusion data link discovery and IGV configuration generation
echo "Discovering mounted data..."
if [ -d "/workspace/data" ]; then
    /usr/local/bin/discover-data-links.sh
    /usr/local/bin/generate-igv-config.sh
    echo "IGV configuration updated with discovered data"
else
    echo "No data directory found, using default configuration"
    cp /opt/igv-webapp/igvwebConfig.template.js /opt/igv-webapp/igvwebConfig.js
fi

# Create nginx configuration with port
sed "s/CONNECT_TOOL_PORT_PLACEHOLDER/${CONNECT_TOOL_PORT}/g" /etc/nginx/sites-available/igv-app > /tmp/nginx.conf
sudo cp /tmp/nginx.conf /etc/nginx/sites-available/igv-app

# Test nginx configuration
sudo nginx -t

# Start nginx in foreground mode
echo "Starting nginx on port ${CONNECT_TOOL_PORT}"
echo "IGV Web App will be available at http://localhost:${CONNECT_TOOL_PORT}"

# Handle SIGTERM gracefully
trap 'echo "Shutting down nginx..."; sudo nginx -s quit; exit 0' SIGTERM

# Start nginx
exec sudo nginx -g 'daemon off;'