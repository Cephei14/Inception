# Developer Documentation - Inception Project

This document provides technical information for developers who want to understand, modify, or extend the Inception infrastructure.

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Project Architecture](#project-architecture)
3. [Building and Launching](#building-and-launching)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Network Configuration](#network-configuration)
7. [Configuration Files](#configuration-files)
8. [Development Workflow](#development-workflow)
9. [Debugging](#debugging)
10. [Project Requirements](#project-requirements)

## Environment Setup

### Prerequisites

Install the required software on your system:

```bash
# Update system packages and other necessary tools
sudo apt update && sudo apt-get install -y ca-certificates curl gnupg sudo git make

# Install Docker and other tools
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && chmod a+r /etc/apt/keyrings/docker.asc
apt-get update && apt-get install -y docker-compose docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
sudo sh get-docker.sh
sudo usermod -aG docker rdhaibi

# Verify installations
docker --version
docker-compose --version
```

### Clone and Configure

```bash
# Clone the project
git clone <repository-url>
cd inception

# Verify project structure
tree -L 3
```

### Set Up Secrets

Create credential files in the `secrets/` directory:

```bash
# These files should NOT be committed to git
mkdir -p /secrets
echo "Banana" > /secrets/db_password.txt
echo "BananaMARIA" > /secrets/db_root_password.txt
printf "WP_ADMIN_PASSWORD=BananaWP\nWP_USER_PASSWORD=RegularUser123\n" > ~/secrets/credentials.txt

# Set appropriate permissions
chmod 600 secrets/*
```

### Configure Environment

Edit `srcs/.env` with your configuration:

```bash
cat > /srcs/.env << 'EOF'
DOMAIN_NAME=rdhaibi.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress
WP_ADMIN_USER=rdhaibi
WP_ADMIN_EMAIL=rdhaibi@student.42.fr
WP_DB_HOST=mariadb
WP_DB_NAME=wordpress_db
WP_DB_USER=wordpress
WP_USER=wpregular
WP_USER_EMAIL=wpuser@student.42.fr
EOF
```

**Required variables**:
- `DOMAIN_NAME`: Your domain (e.g., `login.42.fr`)
- `MYSQL_ROOT_PASSWORD`: MariaDB root password
- `MYSQL_DATABASE`: Database name
- `MYSQL_USER`: Database user
- `MYSQL_PASSWORD`: User password
- `WP_ADMIN_USER`: WordPress admin username (cannot contain "admin")
- `WP_ADMIN_PASSWORD`: WordPress admin password
- `WP_USER`: Regular WordPress user
- `WP_USER_PASSWORD`: Regular user password

### Configure Host

Add domain to `/etc/hosts`:

```bash
sudo sh -c 'echo "127.0.0.1    rdhaibi.42.fr" >> /etc/hosts'
```

## Project Architecture

### Container Overview

```
┌─────────────────────────────────────────────────┐
│                    Host Machine                 │
│  ┌────────────────────────────────────────────┐ │
│  │        Docker Network (bridge)             │ │
│  │                                            │ │
│  │  ┌──────────┐  ┌───────────┐  ┌────────┐   │ │
│  │  │  NGINX   │←→│ WordPress │←→│MariaDB │   │ │
│  │  │  :443    │  │  :9000    │  │ :3306  │   │ │
│  │  └──────────┘  └───────────┘  └────────┘   │ │
│  │       ↓              ↓             ↓       │ │
│  └───────┼──────────────┼─────────────┼───────┘ │
│          ↓              ↓             ↓         │
│    ┌─────────┐   ┌──────────┐  ┌──────────┐     │
│    │  Port   │   │ wordpress│  │ mariadb  │     │
│    │	443    │   │  volume  │  │  volume  │     │
│    └─────────┘   └──────────┘  └──────────┘     │
│                        ↓             ↓          │
│                  /home/rdhaibi/data/            │
└─────────────────────────────────────────────────┘
```

### Service Dependencies

1. **MariaDB** starts first (no dependencies)
2. **WordPress** starts after MariaDB is ready
3. **NGINX** starts after WordPress is ready

### Data Flow

1. User requests `https://rdhaibi.42.fr` (port 443)
2. NGINX receives request, terminates TLS
3. NGINX forwards to WordPress via FastCGI (port 9000)
4. WordPress processes request, queries MariaDB if needed
5. MariaDB returns data to WordPress
6. WordPress generates response
7. NGINX returns HTTPS response to user

## Building and Launching

### Using Makefile

The Makefile provides convenient commands:

```bash
# Create data directories
make data-dirs

# Build all images (first time or after Dockerfile changes)
make build

# Start services in detached mode
make up

# View logs in real-time
make logs

# Stop services (preserves volumes)
make down

# Stop and remove volumes
make clean

# Full cleanup (remove everything)
make fclean

# Rebuild from scratch
make re
```

### Using Docker Compose Directly

```bash
# Build without cache
docker-compose -f srcs/docker-compose.yml build --no-cache

# Start with logs attached
docker-compose -f srcs/docker-compose.yml up

# Start specific service
docker-compose -f srcs/docker-compose.yml up mariadb

# Scale (not applicable here, but possible)
docker-compose -f srcs/docker-compose.yml up --scale wordpress=2
```

## Container Management

### Inspecting Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Inspect container configuration
docker inspect <container_name>

# View container resource usage
docker stats

# View processes inside container
docker top <container_name>
```

### Executing Commands in Containers

```bash
# Access bash shell
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# List WordPress Users (inside wordpress's bash)
wp user list --allow-root
# Filter for WordPress admins
wp user list --role=administrator --allow-root

# Login as a root in MariaDB (inside mariadb's bash)
mysql -u root -p
SHOW DATABASES;

# Run single command
docker exec mariadb mysql -u root -p
docker exec wordpress wp --info --allow-root
docker exec nginx nginx -t

# Run as specific user
docker exec -u www-data wordpress ls -la /var/www/html
```

### Container Logs

```bash
# View all logs
docker logs mariadb
docker logs wordpress
docker logs nginx

# Follow logs (real-time)
docker logs -f wordpress

# Last N lines
docker logs --tail 100 mariadb

# With timestamps
docker logs -t nginx

# Since specific time
docker logs --since 30m wordpress
```

## Volume Management

### Understanding Volumes

The project uses **named volumes** with driver options to store data at specific host locations:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/rdhaibi/data/mariadb
```

This provides:
- Docker volume management benefits
- Data persistence at specific location
- Consistent behavior across environments

### Volume Operations

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data

# Check data on host
ls -lah /home/rdhaibi/data/mariadb/
ls -lah /home/rdhaibi/data/wordpress/

# Backup volumes
sudo tar -czf mariadb_backup.tar.gz /home/rdhaibi/data/mariadb/
sudo tar -czf wordpress_backup.tar.gz /home/rdhaibi/data/wordpress/

# Volume paths
docker volume inspect $(docker volume ls -q -f name=mariadb)
docker volume inspect $(docker volume ls -q -f name=wordpress)

# Restore volumes (when containers are stopped)
sudo tar -xzf mariadb_backup.tar.gz -C /
sudo tar -xzf wordpress_backup.tar.gz -C /
```

### Volume Permissions

```bash
# Check ownership
ls -ld /home/rdhaibi/data/mariadb/
ls -ld /home/rdhaibi/data/wordpress/

```

## Network Configuration

### Network Details

```bash
# List networks
docker network ls

# Inspect inception network
docker network inspect srcs_inception_network

# View DNS resolution
docker exec wordpress nslookup mariadb
docker exec nginx nslookup wordpress

# Check TLS version
echo | openssl s_client -connect rdhaibi.42.fr:443 2>/dev/null | grep -E "Protocol|TLS"
```

### Inter-Container Communication

Containers communicate using service names:
- WordPress connects to MariaDB via hostname `mariadb`
- NGINX connects to WordPress via hostname `wordpress`

```bash
# Test connectivity
docker exec wordpress ping -c 3 mariadb
docker exec nginx curl http://wordpress:9000
```

### Port Mapping

**NGINX**: Host port 443 → Container port 443 (HTTPS only; port 80 is not exposed)
**WordPress**: Port 9000 (internal only, not exposed to host)
**MariaDB**: Port 3306 (internal only, not exposed to host)

## Configuration Files

### NGINX Configuration

**Location**: `srcs/requirements/nginx/conf/nginx.conf`

Key sections:
- **HTTP to HTTPS redirect**: Server block on port 80
- **TLS configuration**: SSL protocols, ciphers
- **FastCGI proxy**: Forward PHP requests to WordPress
- **Security headers**: Prevent access to hidden files

**Testing configuration**:
```bash
docker exec nginx nginx -t
```

### WordPress PHP-FPM Configuration

**Location**: `srcs/requirements/wordpress/conf/www.conf`

Key settings:
- Listen on port 9000
- User/group: www-data
- Process management (pm.*)
- PHP settings

**Checking configuration**:
```bash
docker exec wordpress php-fpm8.2 -t
```

### MariaDB Configuration

**Location**: `srcs/requirements/mariadb/conf/my.cnf`

Key settings:
- Bind address: 0.0.0.0 (accept from any container)
- Character set: utf8mb4
- Max connections
- Buffer sizes

**Checking configuration**:
```bash
docker exec mariadb mysqld --help --verbose | grep -A 1 "Default options"
# Root login without password FAILS
docker exec mariadb mysql -u root -e "SELECT 1"

# User login with password SUCCEEDS
docker exec mariadb mysql -u wordpress -pBanana -h 127.0.0.1 wordpress_db -e "SHOW TABLES;"

# Login as root WITH password to check what users exist
docker exec mariadb mysql -u root -p'BananaMARIA' -e "SELECT user,host FROM mysql.user;"

```

### Docker Compose Configuration

**Location**: `srcs/docker-compose.yml`

Defines:

- Service build contexts and Dockerfiles
- Environment variables from `.env`
- Volume mounts
- Network configuration
- Restart policies
- Dependencies (depends_on)

## Development Workflow

### Making Changes

#### 1. Modify Configuration Files

After editing configuration files:

```bash
# Stop services
make down

# Rebuild affected service
docker-compose -f srcs/docker-compose.yml build nginx  # or mariadb, wordpress

# Restart
make up
```

#### 2. Modify Dockerfiles

After editing Dockerfiles:

```bash
# Clean build (no cache)
docker-compose -f srcs/docker-compose.yml build --no-cache <service>

# Or rebuild everything
make fclean
make build up
```

#### 3. Modify Entrypoint Scripts

After editing entrypoint scripts:

```bash
# Rebuild the service (entrypoints are copied during build)
docker-compose -f srcs/docker-compose.yml build <service>
make up
```

### Testing Changes

```bash
# Test individual services
docker-compose -f srcs/docker-compose.yml up mariadb  # Test MariaDB alone

# Check service health
docker exec mariadb mysqladmin ping -p
docker exec wordpress wp core version --allow-root
docker exec nginx nginx -v

# Validate configurations
docker exec nginx nginx -t
docker exec wordpress php-fpm8.2 -t
```

### Adding New Services

To add a bonus service:

1. Create directory: `srcs/requirements/<service>/`
2. Add Dockerfile, conf/, and tools/
3. Update `docker-compose.yml`:
   ```yaml
   new_service:
     build: ./requirements/new_service
     image: new_service:inception
     # ... other configuration
   ```
4. Update Makefile if needed

## Debugging

### Common Issues

#### Containers Exit Immediately

```bash
# Check exit code and logs
docker ps -a
docker logs <container_name>

# Common causes:
# - Syntax error in entrypoint script
# - Missing environment variable
# - Port already in use
# - Permission issues
```

#### WordPress Can't Connect to Database

```bash
# Verify MariaDB is running
docker ps | grep mariadb

# Check environment variables match
docker exec wordpress env | grep -E 'WP_DB|MYSQL'
docker exec mariadb env | grep MYSQL

# Test connection manually
docker exec wordpress mysql -hmariadb -uwordpress -pBanana wordpress_db -e "SELECT VERSION();"
```

#### Permission Denied Errors

```bash
# Check file owners in containers
docker exec wordpress ls -la /var/www/html
docker exec mariadb ls -la /var/lib/mysql

# Check host directories
ls -la /home/rdhaibi/data/

# Fix if needed (example for WordPress)
docker exec wordpress chown -R www-data:www-data /var/www/html
```

#### SSL Certificate Issues

```bash
# Verify certificates exist
docker exec nginx ls -la /etc/nginx/certs/

# Check certificate details
docker exec nginx openssl x509 -in /etc/nginx/certs/server.crt -text -noout

# Regenerate if needed (from host)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout srcs/requirements/nginx/tools/certs/server.key \
    -out srcs/requirements/nginx/tools/certs/server.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=rdhaibi.42.fr"
```

### Advanced Debugging

#### Container Shell Access

```bash
# Access with bash
docker exec -it mariadb bash

# If bash not available, use sh
docker exec -it alpine-based-container sh

# Run as root (if needed for debugging)
docker exec -u root wordpress bash
```

#### Network Debugging

```bash
# Install network tools in container (temporary)
docker exec -u root wordpress apt update && apt install -y iputils-ping net-tools dnsutils

# Test DNS resolution
docker exec wordpress nslookup mariadb
docker exec wordpress dig mariadb

# Test connectivity
docker exec wordpress ping mariadb
docker exec nginx telnet wordpress 9000
```

#### File System Debugging

```bash
# Copy files from container
docker cp wordpress:/var/www/html/wp-config.php ./debug/

# Copy files to container
docker cp fixed-file.txt wordpress:/var/www/html/

# View file differences
docker exec wordpress diff file1 file2
```

## Project Requirements

### Mandatory Requirements Checklist

- [x] Three containers: NGINX, WordPress, MariaDB
- [x] NGINX with TLSv1.2/TLSv1.3 only
- [x] WordPress + php-fpm (no nginx)
- [x] MariaDB only (no nginx)
- [x] Two named volumes (database + website files)
- [x] Volumes in `/home/login/data/`
- [x] Docker network connecting containers
- [x] Containers restart on crash
- [x] Own Dockerfiles (no pull except Alpine/Debian)
- [x] Alpine/Debian base images
- [x] No latest tag
- [x] No passwords in Dockerfiles
- [x] Use environment variables
- [x] `.env` file for variables
- [x] Two WordPress users (one admin, username can't contain admin)
- [x] NGINX as only entrypoint via port 443
- [x] Domain name: `login.42.fr`
- [x] No `network: host` or `--link`
- [x] No infinite loops (tail -f, sleep infinity, while true)

### Best Practices Implemented

- ✅ PID 1 proper daemon management
- ✅ Health checks and wait conditions
- ✅ Proper error handling in entrypoints
- ✅ Security: least privilege, no root when possible
- ✅ Logging to stdout/stderr
- ✅ Graceful shutdown handling
- ✅ Idempotent entrypoint scripts
- ✅ Proper Docker layer caching

### File Structure Compliance

```
inception/
├── Makefile                    ✅
├── secrets/                    ✅
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
├── README.md                   ✅
├── USER_DOC.md                 ✅
├── DEV_DOC.md                  ✅
└── srcs/
    ├── docker-compose.yml      ✅
    ├── .env                    ✅ (git-ignored)
    └── requirements/
        ├── mariadb/            ✅
        ├── nginx/              ✅
        └── wordpress/          ✅
```

## Resources for Developers

### Docker References
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Storage Documentation](https://docs.docker.com/storage/)

### Service Documentation
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)

### Security
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

## Conclusion

This developer documentation should provide everything needed to understand, modify, and debug the Inception project. For user-facing information, see [USER_DOC.md](USER_DOC.md). For project overview and requirements, see [README.md](README.md).

---

**Happy coding! 🐳**
