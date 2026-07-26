module "app_stack" {
  source = "../../modules/app-stack"

  environment       = "production"
  edge_host_port    = 8080
  api_replica_count = 2 # bigger footprint than staging - same module, different input
  api_memory_mb     = 256
  db_cpu_shares     = 512

  db_password = var.db_password # TF_VAR_db_password in CI, never hardcoded
}

output "edge_url" {
  value = module.app_stack.edge_url
}

output "networks" {
  value = module.app_stack.networks
}
