
DC=docker compose
PRI=cluster-pri
PERF=cluster-perf
DR=cluster-dr
PRI_CONT=vault-enterprise-cluster-pri
PERF_CONT=vault-enterprise-cluster-perf
DR_CONT=vault-enterprise-cluster-dr

# Function to extract and clean a value from init file
# Extracts a value matching the pattern and removes ANSI color codes
# Usage: $(call extract_value,Unseal Key 1,$(PRI)/.init)
define extract_value
$$(awk -F': ' '/^$(1):/ {print $$2}' $(2) | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')
endef

.DEFAULT_GOAL := up

up:
	$(DC) up --build --detach

init:
	docker exec -i $(PRI_CONT) vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > $(PRI)/.init
	docker exec -i $(PERF_CONT) vault operator init -address=http://127.0.0.1:8210 -key-shares=1 -key-threshold=1 > $(PERF)/.init
	docker exec -i $(DR_CONT) vault operator init -address=http://127.0.0.1:8220 -key-shares=1 -key-threshold=1 > $(DR)/.init

unseal:
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PRI_CONT) vault operator unseal -address=http://127.0.0.1:8200 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PERF_CONT) vault operator unseal -address=http://127.0.0.1:8210 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(DR_CONT) vault operator unseal -address=http://127.0.0.1:8220 $$key; \
	done


# Establish performance replication between the primary and performance clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-pr:
	@PRI_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init); \
	PERF_TOKEN=$(call extract_value,Initial Root Token,$(PERF)/.init); \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write -f sys/replication/performance/primary/enable; \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write sys/replication/performance/primary/secondary-token id=secondary -format=json | jq -r '.wrap_info.token' > $(PERF)/.perf_token; \
	VAULT_ADDR=http://127.0.0.1:8210 VAULT_TOKEN=$$PERF_TOKEN vault write sys/replication/performance/secondary/enable token=$$(cat $(PERF)/.perf_token)


# Establish disaster recovery (DR) replication between the primary and DR clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-dr:
	@PRI_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init); \
	DR_TOKEN=$(call extract_value,Initial Root Token,$(DR)/.init); \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write -f sys/replication/dr/primary/enable primary_cluster_addr=http://vault-enterprise-cluster-pri:8201; \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write sys/replication/dr/primary/secondary-token id=dr-secondary -format=json | jq -r '.wrap_info.token' > $(DR)/.dr_token; \
	VAULT_ADDR=http://127.0.0.1:8220 VAULT_TOKEN=$$DR_TOKEN vault write sys/replication/dr/secondary/enable token=$$(cat $(DR)/.dr_token)

down:
	$(DC) down --volumes
	sudo rm -rf cluster-pri/data/*
	sudo rm -rf cluster-perf/data/*
	sudo rm -rf cluster-dr/data/*

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
	@echo "make init: Initialize all Vault clusters"
	@echo "make unseal: Unseal all Vault clusters"
	@echo "make establish-pr: Setup Performance Replication"
	@echo "make establish-dr: Setup DR Replication"
