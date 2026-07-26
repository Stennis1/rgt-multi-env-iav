terraform {
  backend "s3" {
    bucket = "tfstate"
    key    = "production/terraform.tfstate" # different key = different state file = staging cannot mutate this
    region = "us-east-1"

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

    use_lockfile = true
  }
}
