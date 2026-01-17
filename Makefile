
DC=docker compose
PRI=cluster-pri
PERF=cluster-perf
DR=cluster-dr
PRI_CONT=vault-enterprise-cluster-pri
PERF_CONT=vault-enterprise-cluster-perf
DR_CONT=vault-enterprise-cluster-dr

# Token extraction helpers
STRIP_ANSI = sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n'
EXTRACT_TOKEN = awk '/Initial Root Token/ {print $$NF}' | $(STRIP_ANSI)
EXTRACT_UNSEAL_KEY = awk '/Unseal Key 1/ {print $$NF}' | $(STRIP_ANSI)
GET_PRI_TOKEN = $$(cat $(PRI)/.init | $(EXTRACT_TOKEN))
GET_PERF_TOKEN = $$(cat $(PERF)/.init | $(EXTRACT_TOKEN))
GET_DR_TOKEN = $$(cat $(DR)/.init | $(EXTRACT_TOKEN))
GET_PRI_UNSEAL = $$(cat $(PRI)/.init | $(EXTRACT_UNSEAL_KEY))
GET_PERF_UNSEAL = $$(cat $(PERF)/.init | $(EXTRACT_UNSEAL_KEY))
GET_DR_UNSEAL = $$(cat $(DR)/.init | $(EXTRACT_UNSEAL_KEY))

.DEFAULT_GOAL := up

up:
	$(DC) up --build --detach

init:
	docker exec -i $(PRI_CONT) vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > $(PRI)/.init
	docker exec -i $(PERF_CONT) vault operator init -address=http://127.0.0.1:8210 -key-shares=1 -key-threshold=1 > $(PERF)/.init
	docker exec -i $(DR_CONT) vault operator init -address=http://127.0.0.1:8220 -key-shares=1 -key-threshold=1 > $(DR)/.init

unseal:
	docker exec -it $(PRI_CONT) vault operator unseal -address=http://127.0.0.1:8200 $(GET_PRI_UNSEAL)
	docker exec -it $(PERF_CONT) vault operator unseal -address=http://127.0.0.1:8210 $(GET_PERF_UNSEAL)
	docker exec -it $(DR_CONT) vault operator unseal -address=http://127.0.0.1:8220 $(GET_DR_UNSEAL)

# Establish performance replication between the primary and performance clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-pr:
	VAULT_TOKEN=$(GET_PRI_TOKEN) VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/performance/primary/enable
	VAULT_TOKEN=$(GET_PRI_TOKEN) VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/performance/primary/secondary-token id=secondary -format=json | jq -r '.wrap_info.token' > $(PERF)/.perf_token
	VAULT_TOKEN=$(GET_PERF_TOKEN) VAULT_ADDR=http://127.0.0.1:8210 vault write sys/replication/performance/secondary/enable token=$$(cat $(PERF)/.perf_token)

# Establish disaster recovery (DR) replication between the primary and DR clusters.
# Prerequisites: run 'make init' and 'make unseal' so all clusters are initialized and unsealed.
establish-dr:
	VAULT_TOKEN=$(GET_PRI_TOKEN) VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/dr/primary/enable primary_cluster_addr=http://vault-enterprise-cluster-pri:8201
	VAULT_TOKEN=$(GET_PRI_TOKEN) VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/dr/primary/secondary-token id=dr-secondary -format=json | jq -r '.wrap_info.token' > $(DR)/.dr_token
	VAULT_TOKEN=$(GET_DR_TOKEN) VAULT_ADDR=http://127.0.0.1:8220 vault write sys/replication/dr/secondary/enable token=$$(cat $(DR)/.dr_token)

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
	@echo "make init: Initialize all Vault clusters"
	@echo "make unseal: Unseal all Vault clusters"
	@echo "make establish-pr: Setup Performance Replication"
	@echo "make establish-dr: Setup DR Replication"
