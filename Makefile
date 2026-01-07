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
	@echo "Usage: make [up|down|restart|logs|ps|build|help]"
