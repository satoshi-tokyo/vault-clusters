# vault-clusters
This repo is intended for lab use to test Vault DR and PR replications.
## Bring up containers
This will bring up containers without replication setup.
```shell
% git clone git@github.com:hashicorp-japan/vault-tools.git
% cd vault-clusters/

# start
% export VAULT_LICENSE=$(cat ${path_to_your_license_file})
% docker compose up --build --detach

# cleanup
% docker compose down --volumes
% rm -rf cluster-{pri,dr,perf}/data/*
```

## Export env
```
export PRI_ADDR="http://127.0.0.1:8200"
export PERF_ADDR="http://127.0.0.1:8210"
export DR_ADDR="http://127.0.0.1:8220"
export PRI_CL_ADDR="http://vault-enterprise-cluster-pri:8201"
```

## Init
### Primary cluster:
```
$ docker exec -it vault-enterprise-cluster-pri vault operator init \
    -address=${PRI_ADDR} \
    -key-shares=1 \
    -key-threshold=1 \
    > $PWD/cluster-pri/.init

$ docker exec -it vault-enterprise-cluster-pri \
    vault operator unseal -address=${PRI_ADDR} <CLUSTER_PRI_UNSEAL_KEY>
```

### Performance cluster
```
$ docker exec -it vault-enterprise-cluster-perf \
  vault operator init \
    -address=${PERF_ADDR} \
    -key-shares=1 \
    -key-threshold=1 \
    > $PWD/cluster-perf/.init

$ docker exec -it vault-enterprise-cluster-perf \
    vault operator unseal -address=${PERF_ADDR} <CLUSTER_PERF_UNSEAL_KEY>
```

### DR cluster
```
$ docker exec -it vault-enterprise-cluster-dr \
  vault operator init \
    -address=${DR_ADDR} \
    -key-shares=1 \
    -key-threshold=1 \
    > $PWD/cluster-dr/.init

$ docker exec -it vault-enterprise-cluster-dr \
    vault operator unseal -address=${DR_ADDR} <CLUSTER_DR_UNSEAL_KEY>
```

## Setup user
```
$ VAULT_ADDR=${PRI_ADDR} vault login
Token (will be hidden): <CLUSTER_PRI_ROOT_TOKEN>

$ vault policy write -address=${PRI_ADDR} superpolicy -<<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
Success! Uploaded policy: superpolicy

$ vault auth enable -address=${PRI_ADDR} userpass
Success! Enabled userpass auth method at: userpass/

$ vault write -address=${PRI_ADDR} auth/userpass/users/superuser \
    password="vaultMagic" policies="superpolicy"
Success! Data written to: auth/userpass/users/superuser
```

## Setup Performance replication
```
$ vault write -address=${PRI_ADDR} -f sys/replication/performance/primary/enable
WARNING! The following warnings were returned from Vault:

  * This cluster is being enabled as a primary for replication. Vault will be
  unavailable for a brief period and will resume service shortly.

$ vault write -address=${PRI_ADDR} \
    sys/replication/performance/primary/secondary-token id=secondary -format=json \
    | jq -r '.wrap_info | .token'
eyJhbGciOiJFUzUxMiI ... output omitted ... eC9nDdQLMVxlrC7

$ VAULT_ADDR=${PERF_ADDR} vault login
Token (will be hidden): <CLUSTER_PERF_ROOT_TOKEN>

$ VAULT_TOKEN=<CLUSTER_PERF_ROOT_TOKEN> VAULT_ADDR=${PERF_ADDR} vault write -address=${PERF_ADDR} \
    sys/replication/performance/secondary/enable \
    token=eyJhbGciOiJFUzUxMiI ... output omitted ... eC9nDdQLMVxlrC7
```

## Setup DR
```
$ VAULT_ADDR=${PRI_ADDR} VAULT_TOKEN=<CLUSTER_PRI_ROOT_TOKEN> \
    vault write -f sys/replication/dr/primary/enable \
    primary_cluster_addr=${PRI_CL_ADDR}
WARNING! The following warnings were returned from Vault:

  * This cluster is being enabled as a primary for replication. Vault will be
  unavailable for a brief period and will resume service shortly.

$ VAULT_ADDR=${PRI_ADDR} VAULT_TOKEN=<CLUSTER_PRI_ROOT_TOKEN> \
    vault write sys/replication/dr/primary/secondary-token id=dr-secondary \
    -format=json | jq -r '.wrap_info | .token'

$ VAULT_ADDR=${DR_ADDR} VAULT_TOKEN=<CLUSTER_DR_ROOT_TOKEN> \
    vault write sys/replication/dr/secondary/enable \
    token=eyJhbGc... output omitted ...Kqxg3t
```
