ui = true
disable_mlock = true
api_addr = "http://cluster-dr-nd-3:8224"
cluster_addr = "http://cluster-dr-nd-3:8225"

listener "tcp" {
  address = "0.0.0.0:8224"
  cluster_address = "0.0.0.0:8225"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_3"
  retry_join {
    leader_api_addr = "http://cluster-dr-nd-1:8220"
  }
}