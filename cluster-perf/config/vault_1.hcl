ui = true
disable_mlock = true
api_addr = "http://cluster-perf-nd-1:8210"
cluster_addr = "http://cluster-perf-nd-1:8211"

listener "tcp" {
  address = "0.0.0.0:8210"
  cluster_address = "0.0.0.0:8211"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_1"
}