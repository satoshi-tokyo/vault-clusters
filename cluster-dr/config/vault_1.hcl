ui = true
disable_mlock = true
api_addr = "http://cluster-dr-nd-1:8220"
cluster_addr = "http://cluster-dr-nd-1:8221"

listener "tcp" {
  address = "0.0.0.0:8220"
  cluster_address = "0.0.0.0:8221"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_1"
}