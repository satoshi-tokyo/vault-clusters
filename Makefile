
DC=docker compose
PRI=cluster-pri
PERF=cluster-perf
DR=cluster-dr
PRI_CONT_NODE_1=cluster-pri-nd-1
PRI_CONT_NODE_2=cluster-pri-nd-2
PRI_CONT_NODE_3=cluster-pri-nd-3
PERF_CONT_NODE_1=cluster-perf-nd-1
PERF_CONT_NODE_2=cluster-perf-nd-2
PERF_CONT_NODE_3=cluster-perf-nd-3
DR_CONT_NODE_1=cluster-dr-nd-1
DR_CONT_NODE_2=cluster-dr-nd-2
DR_CONT_NODE_3=cluster-dr-nd-3

# Function to extract and clean a value from init file
# Extracts a value matching the pattern and removes ANSI color codes
# Usage: $(call extract_value,Unseal Key 1,$(PRI)/.init)
define extract_value
$$(awk -F': ' '/^$(1):/ {print $$2}' $(2) | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')
endef

.DEFAULT_GOAL := help

up: ## Spin-up Vault clusters
	$(DC) up --build --detach

init: ## Initialize Vault clusters
	docker exec -i $(PRI_CONT_NODE_1) vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > $(PRI)/.init
	docker exec -i $(PERF_CONT_NODE_1) vault operator init -address=http://127.0.0.1:8210 -key-shares=1 -key-threshold=1 > $(PERF)/.init
	docker exec -i $(DR_CONT_NODE_1) vault operator init -address=http://127.0.0.1:8220 -key-shares=1 -key-threshold=1 > $(DR)/.init

unseal: ## Unseal Vault cluster
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PRI_CONT_NODE_1) vault operator unseal -address=http://127.0.0.1:8200 $$key; \
	done
	sleep 3
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PRI_CONT_NODE_2) vault operator unseal -address=http://127.0.0.1:8202 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PRI_CONT_NODE_3) vault operator unseal -address=http://127.0.0.1:8204 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PERF_CONT_NODE_1) vault operator unseal -address=http://127.0.0.1:8210 $$key; \
	done
	sleep 3
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PERF_CONT_NODE_2) vault operator unseal -address=http://127.0.0.1:8212 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(PERF_CONT_NODE_3) vault operator unseal -address=http://127.0.0.1:8214 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(DR_CONT_NODE_1) vault operator unseal -address=http://127.0.0.1:8220 $$key; \
	done
	sleep 3
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(DR_CONT_NODE_2) vault operator unseal -address=http://127.0.0.1:8222 $$key; \
	done
	@for key in $(shell awk '/Unseal Key/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g'); do \
		docker exec -it $(DR_CONT_NODE_3) vault operator unseal -address=http://127.0.0.1:8224 $$key; \
	done

# Establish performance replication between the primary and performance clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-pr: ## Establish Vault PR Replication
	@PRI_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init); \
	PERF_TOKEN=$(call extract_value,Initial Root Token,$(PERF)/.init); \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write -f sys/replication/performance/primary/enable; \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write sys/replication/performance/primary/secondary-token id=secondary -format=json | jq -r '.wrap_info.token' > $(PERF)/.perf_token; \
	VAULT_ADDR=http://127.0.0.1:8210 VAULT_TOKEN=$$PERF_TOKEN vault write sys/replication/performance/secondary/enable token=$$(cat $(PERF)/.perf_token)


# Establish disaster recovery (DR) replication between the primary and DR clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-dr: ## Establish Vault DR Replication
	@PRI_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init); \
	DR_TOKEN=$(call extract_value,Initial Root Token,$(DR)/.init); \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write -f sys/replication/dr/primary/enable; \
	VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$$PRI_TOKEN vault write sys/replication/dr/primary/secondary-token id=dr-secondary -format=json | jq -r '.wrap_info.token' > $(DR)/.dr_token; \
	VAULT_ADDR=http://127.0.0.1:8220 VAULT_TOKEN=$$DR_TOKEN vault write sys/replication/dr/secondary/enable token=$$(cat $(DR)/.dr_token)

down: ## Clean up environment
	$(DC) down --volumes
	sudo rm -rf cluster-pri/data_*/
	sudo rm -rf cluster-perf/data/*
	sudo rm -rf cluster-dr/data/*
	rm -f $(PERF)/.perf_token
	rm -f $(DR)/.dr_token
	rm -f $(PRI)/.init
	rm -f $(PERF)/.init
	rm -f $(DR)/.init
	docker volume prune -f -a

help: ## Print this help
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
