
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
$$(awk '/$(1)/ {print $$$$NF}' $(2) | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')
endef

.DEFAULT_GOAL := up

up:
	$(DC) up --build --detach

init:
	docker exec -i $(PRI_CONT) vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > $(PRI)/.init
	docker exec -i $(PERF_CONT) vault operator init -address=http://127.0.0.1:8210 -key-shares=1 -key-threshold=1 > $(PERF)/.init
	docker exec -i $(DR_CONT) vault operator init -address=http://127.0.0.1:8220 -key-shares=1 -key-threshold=1 > $(DR)/.init

unseal:
	docker exec -it $(PRI_CONT) vault operator unseal -address=http://127.0.0.1:8200 $(call extract_value,Unseal Key 1,$(PRI)/.init)
	docker exec -it $(PERF_CONT) vault operator unseal -address=http://127.0.0.1:8210 $(call extract_value,Unseal Key 1,$(PERF)/.init)
	docker exec -it $(DR_CONT) vault operator unseal -address=http://127.0.0.1:8220 $(call extract_value,Unseal Key 1,$(DR)/.init)

establish-pr:
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init) VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/performance/primary/enable
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init) VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/performance/primary/secondary-token id=secondary -format=json | jq -r '.wrap_info.token' > $(PERF)/.perf_token
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(PERF)/.init) VAULT_ADDR=http://127.0.0.1:8210 vault write sys/replication/performance/secondary/enable token=$$(cat $(PERF)/.perf_token)

establish-dr:
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init) VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/dr/primary/enable primary_cluster_addr=http://vault-enterprise-cluster-pri:8201
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(PRI)/.init) VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/dr/primary/secondary-token id=dr-secondary -format=json | jq -r '.wrap_info.token' > $(DR)/.dr_token
	VAULT_TOKEN=$(call extract_value,Initial Root Token,$(DR)/.init) VAULT_ADDR=http://127.0.0.1:8220 vault write sys/replication/dr/secondary/enable token=$$(cat $(DR)/.dr_token)

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
	@echo "make init: Initialize all Vault clusters"
	@echo "make unseal: Unseal all Vault clusters"
	@echo "make establish-pr: Setup Performance Replication"
	@echo "make establish-dr: Setup DR Replication"
