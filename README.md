# vault-clusters

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
