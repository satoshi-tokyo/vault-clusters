ui = true
disable_mlock = true
api_addr = "http://cluster-pri-nd-1:8200"
cluster_addr = "http://cluster-pri-nd-1:8201"

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_1"
}