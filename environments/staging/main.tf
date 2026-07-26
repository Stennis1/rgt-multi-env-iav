module "app_stack" {
  source = "../../modules/app-stack"

  environment       = "staging"
  edge_host_port    = 8081
  api_replica_count = 1 # smaller footprint than prod - DRY module, different input
  api_memory_mb     = 128
  db_cpu_shares     = 256

  db_password = var.db_password # TF_VAR_db_password in CI, never hardcoded
}

output "edge_url" {
  value = module.app_stack.edge_url
}

output "networks" {
  value = module.app_stack.networks
}
