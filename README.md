# vault-clusters

```shell
% git clone git@github.com:satoshi-tokyo/vault-clusters.git
% cd vault-clusters/

# start
% export VAULT_LICENSE=$(cat ${path_to_your_license_file})
% docker compose up --build --detach

# cleanup
% docker compose down --volumes
% rm -rf cluster-{pri,dr,perf}/data/*
```
