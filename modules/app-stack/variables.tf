variable "environment" {
  description = "Environment name, used to namespace all resources (staging|production)"
  type        = string
}

variable "edge_host_port" {
  description = "Host port published for the edge (nginx) service. Must differ per env to run both stacks on one machine."
  type        = number
}

variable "api_image" {
  description = "Image for the internal API service"
  type        = string
  default     = "hashicorp/http-echo:latest"
}

variable "api_replica_count" {
  description = "Number of API containers (demonstrates DRY sizing per env)"
  type        = number
  default     = 1
}

variable "nginx_image" {
  description = "Image for the public edge reverse proxy"
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "postgres_image" {
  description = "Image for the database tier"
  type        = string
  default     = "postgres:16-alpine"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  description = "DB password. Never set a default; must come from TF_VAR_db_password (CI secret) or a SOPS-encrypted tfvars file."
  type        = string
  sensitive   = true
}

variable "db_cpu_shares" {
  description = "Relative CPU weight - example of a resource limit that differs staging vs prod"
  type        = number
  default     = 512
}

variable "api_memory_mb" {
  description = "Memory limit (MB) for API containers"
  type        = number
  default     = 128
}
