terraform {
  backend "s3" {
    bucket = "tfstate"
    key    = "staging/terraform.tfstate" # isolated key per env - production can never touch this
    region = "us-east-1"                 # required by the S3 backend syntax; meaningless against MinIO

    endpoints = {
      s3 = "http://localhost:9000"
    }

    access_key = "minioadmin"
    secret_key = "minioadmin"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true

    # Native S3 conditional-write locking - no DynamoDB table needed.
    # Requires Terraform >= 1.11 and a MinIO version supporting If-None-Match.
    use_lockfile = true
  }
}
