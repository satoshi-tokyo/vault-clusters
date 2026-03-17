ui = true
disable_mlock = true
api_addr = "http://cluster-dr-nd-2:8222"
cluster_addr = "http://cluster-dr-nd-2:8223"

listener "tcp" {
  address = "0.0.0.0:8222"
  cluster_address = "0.0.0.0:8223"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_2"
  retry_join {
    leader_api_addr = "http://cluster-dr-nd-1:8220"
  }
}