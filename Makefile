# Makefile for Docker Compose operations

DC=docker compose

# Set default target to upbuild, which runs docker compose up --build --detach
.DEFAULT_GOAL := upbuild

upbuild:
	$(DC) up --build --detach

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
