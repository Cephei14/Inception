# Inception

*This project has been created as part of the 42 curriculum by rdhaibi.*

## Description

Inception is a system administration project that focuses on containerization using Docker. The goal is to set up a small infrastructure composed of different services following specific rules and best practices. This project virtualizes several Docker images in a personal virtual machine environment.

The infrastructure consists of:
- **NGINX**: Web server with TLS encryption (TLSv1.2/TLSv1.3)
- **WordPress**: Content Management System with PHP-FPM
- **MariaDB**: Relational database management system

All services run in dedicated containers, communicate through a Docker network, and persist data using Docker volumes. The project emphasizes security, proper configuration, and adherence to Docker best practices.

## Instructions

### Prerequisites

- Linux Virtual Machine (e.g: Debian or Ubuntu)
- Docker Engine
- Docker Compose
- `make` utility
- At least 4GB of free disk space

### Domain Configuration

Before running the project, configure your domain name to point to localhost:

1. Edit your `/etc/hosts` file (requires sudo):
   ```bash
   sudo vim /etc/hosts
   ```

2. Add the following line:
   ```
   127.0.0.1    rdhaibi.42.fr
   ```

### Installation & Execution

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd inception
   ```
   
2. **Copy the repository to the VM**:
   ```bash
   scp -P 2222 -r /home/rdhaibi/Desktop/Inception rdhaibi@localhost:/home/rdhaibi
   ```
   This command assumes your VM is configured with NAT and port forwarding (host port 2222 → guest port 22), general rule :
   ```bash
   scp -r /home/rdhaibi/Desktop/Inception rdhaibi@<VM_IP>:/home/rdhaibi
   ```
   Replace `<VM_IP>` with the IP address shown by `hostname -I` in your VM. Adjust the username and paths as needed for your environment.

3. **Set up secrets and directories** (if not already present):
   ```bash
   # Secrets should already be in the secrets/ folder
   # Do not commit secrets to git
   ls secrets/
   sudo chown -R $(whoami):$(whoami) ~/secrets
   chmod 700 ~/secrets
   chmod 600 ~/secrets/*
   # Should show: credentials.txt, db_password.txt, db_root_password.txt
   mkdir -p /home/rdhaibi/data/mariadb
   mkdir -p /home/rdhaibi/data/wordpress
   sudo chown -R $(whoami):$(whoami) /home/rdhaibi/data
   chmod 700 /home/rdhaibi/data/mariadb /home/rdhaibi/data/wordpress
   ```

4. **Build and start the infrastructure**:
   ```bash
   make build    # Build all Docker images
   make up       # Start all services
   ```

5. **Access the website**:
   - Open your browser and navigate to: `https://rdhaibi.42.fr`
   - Accept the self-signed certificate warning
   - WordPress should be accessible

### Available Make Commands

- `make build` - Build all Docker images
- `make up` - Start all services in detached mode
- `make down` - Stop all services
- `make logs` - Follow real-time logs from all services
- `make clean` - Stop services and remove volumes
- `make fclean` - Full clean (remove images, volumes, and data)
- `make re` - Rebuild everything from scratch
- `make data-dirs` - Create data directories on host

### Stopping the Infrastructure

```bash
make down     # Stop services
make clean    # Stop services and remove volumes
make fclean   # Complete cleanup
```

## Resources

### Docker Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Docker Networks](https://docs.docker.com/network/)

### Service-Specific Documentation
- [NGINX Documentation](https://nginx.org/en/docs/)
- [NGINX SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress Documentation](https://wordpress.org/support/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php)

### Learning Resources
- [Docker Tutorial for Beginners](https://docker-curriculum.com/)
- [Understanding Docker Containers](https://www.docker.com/resources/what-container)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [TLS/SSL Certificates Guide](https://letsencrypt.org/docs/)

### AI Usage

**AI tools were used for the following tasks:**
- Research and understanding of Docker best practices and security guidelines
- Assistance in debugging configuration issues
- Generating boilerplate configuration files (reviewed and customized)
- Understanding complex Docker Compose syntax and networking concepts
- Creating documentation structure and content organization

**AI was NOT used for:**
- Final decision-making on architecture and design choices
- Writing core logic without understanding
- Copying configurations without adaptation to project requirements

All AI-generated content was reviewed, understood, and adapted to meet project-specific requirements.

## Project Description

### Docker Overview

This project uses Docker to containerize three main services: NGINX, WordPress, and MariaDB. Each service runs in isolation within its own container, communicating through a dedicated Docker network.

**Key design choices:**
- **Base Image**: Debian Bookworm (penultimate stable) for all containers
- **No Ready-Made Images**: All containers built from official base images with custom configurations
- **Security**: TLS encryption, environment variables for configuration, proper permission management
- **Persistence**: Named volumes for database and website files
- **Network Isolation**: Custom bridge network for inter-container communication
- **No Hacky Solutions**: Proper daemon management without `tail -f`, `sleep infinity`, or similar workarounds

### Virtual Machines vs Docker
 __________________________________________________________________________________________
| 		Aspect       | 			Virtual Machines 		 | 		Docker Containers 		   |
|--------------------|-----------------------------------|---------------------------------|
| **Architecture**   | Full OS with kernel      		 | Shares host kernel 			   |
| **Size**           | GBs (entire OS)          		 | MBs (app + dependencies) 	   |
| **Startup Time**   | Minutes                  		 | Seconds 						   |
| **Resource Usage** | Heavy (pre-allocated)    		 | Light (dynamic)  			   |
| **Isolation**      | Complete (hardware-level)   		 | Process-level 				   |
| **Portability**    | Lower (platform-dependent)        | Higher (runs anywhere)  		   |
| **Use Case**       | Full OS testing, strong isolation | Microservices, rapid deployment |
|____________________|___________________________________|_________________________________|

**Choice for this project**: Docker containers are ideal because we need lightweight, portable, and easily reproducible services that can start quickly and use resources efficiently.

### Secrets vs Environment Variables
 ____________________________________________________________________________________
| 	   Aspect      |   	          Secrets 		       | 	Environment Variables    |
|------------------|-----------------------------------|-----------------------------|
| **Security**     | Encrypted, restricted access      | Plaintext in container      |
| **Visibility**   | Not in logs/inspect               | Visible in `docker inspect` |
| **Storage**      | Encrypted in Swarm/separate files | In memory, process env      |
| **Best For**     | Passwords, API keys, certs        | Non-sensitive config        |
| **This Project** | Could use for passwords           | Used for general config     |
|__________________|___________________________________|_____________________________|

**Implementation**: This project uses environment variables from `.env` file for general configuration and separate `secrets/` folder for sensitive credentials (kept out of git).

### Docker Network vs Host Network

 ________________________________________________________________________________
|		 Aspect	   |	 Docker Network (Bridge)	| 		Host Network 		 |
|------------------|--------------------------------|----------------------------|
| **Isolation**    | Containers isolated from host  | Direct host network access |
| **Port Mapping** | Explicit port mapping required | Automatic host port usage  |
| **Security**     | Better (isolated) 				| Lower (direct exposure)	 |
| **DNS**          | Built-in service discovery 	| Requires external DNS 	 |
| **Performance**  | Slight overhead (NAT) 			| No overhead 				 |
| **Use Case**     | Microservices, security 		| High performance needs 	 |
|__________________|________________________________|____________________________|

**Choice for this project**: A custom bridge network (`inception_network`) allows containers to communicate with each other by name and provides network isolation between containers. Host access to services (like HTTPS and SSH) is enabled only through explicit port forwarding (e.g., 4443→443 for HTTPS, 2222→22 for SSH) using NAT. This setup is secure and flexible for a multi-service environment, exposing only selected ports to the host.

### Docker Volumes vs Bind Mounts
 ___________________________________________________________________________________________
| 		Aspect	  | 			Docker Volumes				 |		 Bind Mounts			|
|-----------------|------------------------------------------|------------------------------|
| **Management**  | Docker-managed							 | User-managed 				|
| **Location**    | Docker area (`/var/lib/docker/volumes/`) | Any host path 				|
| **Portability** | Portable across systems 				 | Path-dependent 				|
| **Permissions** | Docker handles 							 | Host filesystem permissions  |
| **Backup**      | Docker tools available 					 | Manual/standard tools 		|
| **Best For**    | Production, persistence 				 | Development, sharing files 	|
|_________________|__________________________________________|______________________________|

**Implementation**: This project uses **named volumes with driver options** to store data in `/home/rdhaibi/data/` as required, combining the benefits of Docker volume management with specific host locations.

## Project Structure

```
inception/
├── Makefile                  # Build and management commands
├── secrets/                  # Sensitive credentials (gitignored)
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml    # Service orchestration
    ├── .env                  # Environment variables (gitignored)
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       ├── entrypoint.sh
        │       └── certs/
        │           ├── server.crt
        │           └── server.key
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── entrypoint.sh
```

## License

This project is part of the 42 School curriculum and is intended for educational purposes.
