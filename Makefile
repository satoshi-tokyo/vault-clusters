# Makefile for Docker Compose operations

DC=docker compose

up:
	$(DC) up -d

down:
	$(DC) down

restart:
	$(DC) restart

logs:
	$(DC) logs

ps:
	$(DC) ps

build:
	$(DC) build

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  up       Start Docker Compose services in detached mode"
	@echo "  down     Stop and remove Docker Compose services"
	@echo "  restart  Restart Docker Compose services"
	@echo "  logs     Show logs for Docker Compose services"
	@echo "  ps       List Docker Compose services and their status"
	@echo "  build    Build or rebuild Docker Compose services"
	@echo "  help     Show this help message"
