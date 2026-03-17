ui = true
disable_mlock = true
api_addr = "http://cluster-perf-nd-2:8212"
cluster_addr = "http://cluster-perf-nd-2:8213"

listener "tcp" {
  address = "0.0.0.0:8212"
  cluster_address = "0.0.0.0:8213"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_2"
  retry_join {
    leader_api_addr = "http://cluster-perf-nd-1:8210"
  }
}