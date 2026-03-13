# User Documentation - Inception Project

This document explains how to use the Inception infrastructure as an end user or system administrator.

## Table of Contents

1. [Overview](#overview)
2. [Starting and Stopping the Project](#starting-and-stopping-the-project)
3. [Accessing Services](#accessing-services)
4. [Managing Credentials](#managing-credentials)
5. [Verifying Services](#verifying-services)
6. [Troubleshooting](#troubleshooting)

## Overview

The Inception project provides the following services:

- **NGINX Web Server** (Port 443)
  - Serves as the entry point to the infrastructure
  - Provides HTTPS/TLS encryption (TLSv1.2/TLSv1.3)
  - Port 80 is not exposed; only HTTPS on 443 is available
  
- **WordPress Content Management System**
  - Full-featured blogging and website platform
  - Accessible through NGINX reverse proxy
  - Pre-configured with admin and regular user accounts
  
- **MariaDB Database**
  - Backend database for WordPress
  - Not directly accessible from outside (security)
  - Data persists in Docker volumes

All services are containerized, isolated, and communicate through a private network.

## Starting and Stopping the Project

### Prerequisites

Before starting, ensure:
1. You have Docker and Docker Compose installed
2. Your domain name is configured in `/etc/hosts`:
   ```bash
   127.0.0.1    rdhaibi.42.fr
   ```
3. You are in the project root directory

### Starting the Infrastructure

To start all services:

```bash
make up
```

This command will:
1. Create necessary data directories (`/home/rdhaibi/data/`)
2. Start all three containers (MariaDB → WordPress → NGINX)
3. Run in detached mode (background)

**Expected output:**
```
[+] Running 4/4
 ✔ Network inception_network      Created
 ✔ Container mariadb              Started
 ✔ Container wordpress            Started
 ✔ Container nginx                Started
```

**First-time startup** takes longer (2-3 minutes) because WordPress needs to:
- Download and configure files
- Connect to the database
- Create database tables
- Set up admin and user accounts

### Stopping the Infrastructure

To gracefully stop all services:

```bash
make down
```

This preserves your data (database and WordPress files remain intact).

### Restarting Services

To restart after stopping:

```bash
make up
```

Your data and configuration will be preserved.

### Complete Cleanup

⚠️ **Warning**: This removes all data!

```bash
make fclean
```

This will:
- Stop all containers
- Remove all images
- Delete all persistent data
- Clean up volumes

## Accessing Services

### Accessing the Website

1. **Open your web browser**

2. **Navigate to**: `https://rdhaibi.42.fr`

3. **Accept the security warning**:
   - The website uses a self-signed SSL certificate
   - Click "Advanced" → "Proceed to rdhaibi.42.fr" (Chrome)
   - Or "Accept the Risk and Continue" (Firefox)

4. **You should see the WordPress homepage**

### Accessing the WordPress Admin Panel

1. **Navigate to**: `https://rdhaibi.42.fr/wp-admin`

2. **Login credentials** (from `.env` file):
   - Username: `rdhaibi` (admin user)
   - Password: `BananaWP`

3. **Admin Dashboard**: Full control over website settings, themes, plugins, users, etc.

### Available User Accounts

The infrastructure comes with two predefined users:

 _____________________________________________________________________________
| Username    | 	Role	   | 		Email		   |      Purpose   	  |
|-------------|----------------|-----------------------|----------------------|
| `rdhaibi`   | Administrator  | rdhaibi@student.42.fr | Full site management |
| `wpregular` | 	Author     | wpuser@student.42.fr  |   Content creation   |
|_____________|________________|_______________________|______________________|

## Managing Credentials

### Viewing Credentials

**Method 1**: Check the `.env` file (requires access to the server):

```bash
cat srcs/.env
```

**Method 2**: Check the secrets folder:

```bash
ls -l secrets/
cat secrets/credentials.txt
cat secrets/db_password.txt
cat secrets/db_root_password.txt
```

### Environment Variables

Key configuration variables in `srcs/.env`:

```bash
DOMAIN_NAME=rdhaibi.42.fr              # Website domain
MYSQL_ROOT_PASSWORD=BananaMARIA        # Database root password
MYSQL_DATABASE=wordpress_db            # Database name
MYSQL_USER=wordpress                   # Database user
MYSQL_PASSWORD=Banana                  # Database password
WP_ADMIN_USER=rdhaibi                  # WordPress admin username
WP_ADMIN_PASSWORD=BananaWP             # WordPress admin password
WP_USER=wpregular                      # Regular user username
WP_USER_PASSWORD=RegularUser123        # Regular user password
```

### Changing Credentials

⚠️ **Important**: After changing credentials, you must rebuild:

1. **Stop the infrastructure**:
   ```bash
   make down
   ```

2. **Edit the `.env` file**:
   ```bash
   nano srcs/.env
   ```

3. **Clean and rebuild**:
   ```bash
   make fclean
   make build
   make up
   ```

## Verifying Services

### Check Running Containers

```bash
docker ps
```

**Expected output**:
```
CONTAINER ID   IMAGE                  STATUS          PORTS                           NAMES
abc123...      nginx:inception        Up 2 minutes    0.0.0.0:443->443/tcp    nginx
def456...      wordpress:inception    Up 2 minutes    9000/tcp                        wordpress
ghi789...      mariadb:inception      Up 3 minutes    3306/tcp                        mariadb
```

All three containers should show "Up" status.

### Check Container Logs

**View all logs**:
```bash
make logs
```

**View specific service logs**:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Follow logs in real-time**:
```bash
docker logs -f wordpress
```

### Health Checks

**Test NGINX**:
```bash
curl -k https://rdhaibi.42.fr
```

Should return HTML content.

**Test MariaDB from WordPress container**:
```bash
docker exec wordpress mysql -hmariadb -uwordpress -pBanana -e "SHOW DATABASES;"
```

Should show the WordPress database.

**Test WordPress installation**:
```bash
docker exec -w /var/www/html wordpress wp core is-installed --allow-root
echo $?  #output: 0 (success)
```

### Volume Status

**Check volumes**:
```bash
docker volume ls
```

**Check data on host**:
```bash
ls -lh /home/rdhaibi/data/mariadb/
ls -lh /home/rdhaibi/data/wordpress/
```

Both directories should contain files.

## Troubleshooting

### Services Won't Start

**Problem**: Containers exit immediately after starting.

**Solutions**:
1. Check logs for errors:
   ```bash
   docker logs mariadb
   docker logs wordpress
   docker logs nginx
   ```

2. Verify `.env` file exists and has correct values:
   ```bash
   cat srcs/.env
   ```

3. Check if ports are already in use:
   ```bash
   sudo netstat -tulpn | grep -E ':(443|80)'
   ```

4. Try a clean rebuild:
   ```bash
   make fclean
   make build
   make up
   ```

### Cannot Access Website

**Problem**: Browser shows "Connection refused" or timeout.

**Solutions**:
1. Verify containers are running:
   ```bash
   docker ps
   ```

2. Check NGINX logs:
   ```bash
   docker logs nginx
   ```

3. Verify domain in `/etc/hosts`:
   ```bash
   grep rdhaibi.42.fr /etc/hosts
   ```
   Should show: `127.0.0.1    rdhaibi.42.fr`

4. Try accessing via IP:
   ```bash
   curl -k https://127.0.0.1
   ```

### SSL Certificate Warning

**Problem**: Browser shows security warning.

**Explanation**: This is **normal** because the project uses self-signed certificates (not from a trusted Certificate Authority).

**Solution**: Click "Advanced" and proceed to the site. This is safe for local development.

### WordPress Installation Loop

**Problem**: WordPress asks to install again after restarting.

**Cause**: Data volume was deleted or not mounted correctly.

**Solutions**:
1. Check if volumes exist:
   ```bash
   docker volume ls | grep inception
   ```

2. Check host data directories:
   ```bash
   ls -la /home/rdhaibi/data/wordpress/
   ```

3. Verify volume mounts in containers:
   ```bash
   docker inspect wordpress | grep -A 10 Mounts
   ```

### Database Connection Error

**Problem**: WordPress shows "Error establishing database connection".

**Solutions**:
1. Check if MariaDB is running:
   ```bash
   docker ps | grep mariadb
   ```

2. Verify environment variables match:
   ```bash
   docker exec wordpress env | grep WP_DB
   docker exec mariadb env | grep MYSQL
   ```

3. Test database connection:
   ```bash
   docker exec wordpress mysql -hmariadb -uwordpress -pBanana -e "SELECT 1"
   ```

4. Check MariaDB logs:
   ```bash
   docker logs mariadb
   ```

### Container Keeps Restarting

**Problem**: Container shows "Restarting" status.

**Cause**: Application inside container is crashing.

**Solutions**:
1. View recent logs:
   ```bash
   docker logs --tail 50 <container_name>
   ```

2. Check entrypoint script for errors:
   ```bash
   docker exec <container_name> cat /usr/local/bin/entrypoint.sh
   ```

3. Stop automatic restart and check:
   ```bash
   make down
   docker-compose -f srcs/docker-compose.yml up mariadb
   # Watch output for errors
   ```

## Getting Help

If you encounter issues not covered here:

1. **Check logs**: `make logs` or `docker logs <container>`
2. **Verify configuration**: Ensure `.env` matches your setup
3. **Review the project**: See `README.md` for architecture details
4. **Check Docker status**: `docker info` and `docker ps -a`
5. **Consult DEV_DOC.md**: For technical details and advanced troubleshooting

## Summary of Common Commands

| Task | Command |
|------|---------|
| Start services | `make up` |
| Stop services | `make down` |
| View logs | `make logs` |
| Full cleanup | `make fclean` |
| Rebuild | `make re` |
| Check status | `docker ps` |
| Test website | `curl -k https://rdhaibi.42.fr` |
| Access admin | `https://rdhaibi.42.fr/wp-admin` |

---

**For development and technical details, see [DEV_DOC.md](DEV_DOC.md).**
