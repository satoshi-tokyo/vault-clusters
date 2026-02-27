ui = true
listener "tcp" {
  tls_disable = 1
  address = "[::]:8220"
  cluster_address = "[::]:8221"
}

disable_mlock = true

storage "raft" {
  path = "/vault/file"
}