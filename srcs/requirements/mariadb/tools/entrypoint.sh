#!/bin/bash
set -e

# Read passwords from Docker secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Only run initialization on first boot
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Start MariaDB temporarily for setup
    mysqld --user=mysql --skip-networking &
    MYSQLD_PID=$!

    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mysqladmin ping --silent 2>/dev/n6'ull; then
            break
        fi
        sleep 1
    done

    # Run initial setup
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Gracefully stop temporary instance
    mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $MYSQLD_PID
    echo "MariaDB initialized successfully."
else
    echo "MariaDB data directory already exists, skipping initialization."
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql


