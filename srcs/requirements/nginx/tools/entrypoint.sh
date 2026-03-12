#!/bin/bash
set -e

# Wait for WordPress to be ready
echo "Waiting for WordPress to be available..."
until nc -z wordpress 9000 2>/dev/null; do
    sleep 1
done

echo "Starting NGINX..."
exec nginx -g "daemon off;"
