ui = true
disable_mlock = true
api_addr = "http://vault-ent-pri-nd-2:8202"
cluster_addr = "http://vault-ent-pri-nd-2:8203"

listener "tcp" {
  address = "0.0.0.0:8202"
  cluster_address = "0.0.0.0:8203"
  tls_disable = 1
}

storage "raft" {
  path = "/vault/file"
  node_id = "vault_2"
  retry_join {
    leader_api_addr = "http://vault-ent-pri-nd-1:8200"
  }
}