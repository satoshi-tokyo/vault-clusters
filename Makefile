
DC=docker compose
PRI=cluster-pri
PERF=cluster-perf
DR=cluster-dr
PRI_CONT=vault-enterprise-cluster-pri
PERF_CONT=vault-enterprise-cluster-perf
DR_CONT=vault-enterprise-cluster-dr

.DEFAULT_GOAL := up

up:
	$(DC) up --build --detach

init:
	docker exec -it $(PRI_CONT) vault operator init -address=http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > $(PRI)/.init
	docker exec -it $(PERF_CONT) vault operator init -address=http://127.0.0.1:8210 -key-shares=1 -key-threshold=1 > $(PERF)/.init
	docker exec -it $(DR_CONT) vault operator init -address=http://127.0.0.1:8220 -key-shares=1 -key-threshold=1 > $(DR)/.init

unseal:
	docker exec -it $(PRI_CONT) vault operator unseal -address=http://127.0.0.1:8200 $$(awk '/Unseal Key 1/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')
	docker exec -it $(PERF_CONT) vault operator unseal -address=http://127.0.0.1:8210 $$(awk '/Unseal Key 1/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')
	docker exec -it $(DR_CONT) vault operator unseal -address=http://127.0.0.1:8220 $$(awk '/Unseal Key 1/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n')

establish-pr:
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/performance/primary/enable
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/performance/primary/secondary-token id=secondary -format=json | jq -r '.wrap_info.token' > $(PERF)/.perf_token
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(PERF)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8210 vault write sys/replication/performance/secondary/enable token=$$(cat $(PERF)/.perf_token)

establish-dr:
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8200 vault write -f sys/replication/dr/primary/enable primary_cluster_addr=http://vault-enterprise-cluster-pri:8201
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(PRI)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8200 vault write sys/replication/dr/primary/secondary-token id=dr-secondary -format=json | jq -r '.wrap_info.token' > $(DR)/.dr_token
	VAULT_TOKEN=$$(awk '/Initial Root Token/ {print $$NF}' $(DR)/.init | sed 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n') VAULT_ADDR=http://127.0.0.1:8220 vault write sys/replication/dr/secondary/enable token=$$(cat $(DR)/.dr_token)

help:
	@echo "Usage: make (default)"
	@echo "Runs: 'docker compose up --build --detach'"
	@echo "make init: Initialize all Vault clusters"
	@echo "make unseal: Unseal all Vault clusters"
	@echo "make establish-pr: Setup Performance Replication"
	@echo "make establish-dr: Setup DR Replication"
