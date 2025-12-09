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

# Run Fusion data link discovery and IGV configuration generation
echo "Discovering Fusion-mounted data links..."
if [ -d "/workspace/data" ]; then
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