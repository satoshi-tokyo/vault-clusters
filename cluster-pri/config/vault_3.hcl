ui = true
disable_mlock = true
api_addr = "http://cluster-pri-nd-3:8204"
cluster_addr = "http://cluster-pri-nd-3:8205"

listener "tcp" {
  address = "0.0.0.0:8204"
  cluster_address = "0.0.0.0:8205"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_3"
  retry_join {
    leader_api_addr = "http://cluster-pri-nd-1:8200"
  }
}