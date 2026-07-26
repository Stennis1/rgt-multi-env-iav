variable "db_password" {
  description = "Supplied via TF_VAR_db_password (GitHub Actions secret) or a SOPS-encrypted secrets.auto.tfvars - never committed in plaintext"
  type        = string
  sensitive   = true
}
