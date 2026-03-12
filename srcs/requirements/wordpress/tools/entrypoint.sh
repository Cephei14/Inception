#!/bin/bash
set -e

# Read passwords from Docker secrets
WP_DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/wp_credentials | cut -d'=' -f2-)
WP_USER_PASSWORD=$(grep '^WP_USER_PASSWORD=' /run/secrets/wp_credentials | cut -d'=' -f2-)

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until /usr/bin/mysql -h"${WP_DB_HOST}" -u"${WP_DB_USER}" -p"${WP_DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done
echo "MariaDB is up and running!"

cd /var/www/html

# Create wp-config.php if it doesn't exist
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${WP_DB_NAME}" \
        --dbuser="${WP_DB_USER}" \
        --dbpass="${WP_DB_PASSWORD}" \
        --dbhost="${WP_DB_HOST}" \
        --allow-root
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception WordPress" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    echo "WordPress installed successfully!"
else
    echo "WordPress is already installed"
fi

# Create a second non-admin user (required by project)
if [ -n "${WP_USER}" ] && [ -n "${WP_USER_PASSWORD}" ] && [ -n "${WP_USER_EMAIL}" ]; then
    if ! wp user get "${WP_USER}" --field=login --allow-root > /dev/null 2>&1; then
        echo "Creating regular WordPress user..."
        wp user create "${WP_USER}" "${WP_USER_EMAIL}" --role=author --user_pass="${WP_USER_PASSWORD}" --allow-root
        echo "Regular user created successfully!"
    else
        echo "Regular user already exists"
    fi
fi

# Fix permissions
chown -R www-data:www-data /var/www/html

# Detect PHP-FPM version dynamically
PHP_FPM=$(find /usr/sbin -name 'php-fpm*' | head -1)
echo "Starting PHP-FPM (${PHP_FPM})..."
exec ${PHP_FPM} -F
