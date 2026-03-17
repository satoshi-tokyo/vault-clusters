ui = true
disable_mlock = true
api_addr = "http://cluster-perf-nd-3:8214"
cluster_addr = "http://cluster-perf-nd-3:8215"

listener "tcp" {
  address = "0.0.0.0:8214"
  cluster_address = "0.0.0.0:8215"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_3"
  retry_join {
    leader_api_addr = "http://cluster-perf-nd-1:8210"
  }
}