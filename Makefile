# Makefile for Docker Compose operations


DC=docker compose

# Default target: run docker compose up --build --detach
.DEFAULT_GOAL := upbuild

upbuild:
	$(DC) up --build --detach

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
