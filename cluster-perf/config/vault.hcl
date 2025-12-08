ui = true
listener "tcp" {
  tls_disable = 1
  address = "[::]:8210"
  cluster_address = "[::]:8211"
}

disable_mlock = true

storage "raft" {
  path = "/vault/file"
}