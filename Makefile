.PHONY: build up down logs clean fclean re help data-dirs

help:
	@echo "Available commands:"
	@echo "  make build       - Build Docker images"
	@echo "  make up          - Start services"
	@echo "  make down        - Stop services"
	@echo "  make logs        - Follow service logs"
	@echo "  make clean       - Stop services and remove volumes"
	@echo "  make fclean      - Full clean (remove images, volumes, data)"
	@echo "  make re          - Rebuild everything from scratch"
	@echo "  make data-dirs   - Create data directories"

data-dirs:
	@mkdir -p /home/cepheus/data/mariadb
	@mkdir -p /home/cepheus/data/wordpress
	@echo "Data directories created"

build: data-dirs
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env build

up: data-dirs
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env up -d

down:
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env down

logs:
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env logs -f

clean: down
	docker-compose -f srcs/docker-compose.yml --env-file srcs/.env down -v

fclean: clean
	@docker rmi -f mariadb:inception wordpress:inception nginx:inception 2>/dev/null || true
	@sudo rm -rf /home/cepheus/data/mariadb/* /home/cepheus/data/wordpress/*
	@echo "Full clean completed"

re: fclean build up