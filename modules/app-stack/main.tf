terraform {
  required_version = ">= 1.11"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# ---------- Database tier ----------
# Attached ONLY to db_internal. No published host port anywhere in this block -
# that absence is what enforces "no public ingress".
resource "docker_image" "postgres" {
  name = var.postgres_image
}

resource "docker_container" "postgres" {
  name  = "${var.environment}-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name = docker_network.db_internal.name
  }

  # deliberately no `ports {}` block - this is the "no public IP" analog
  cpu_shares = var.db_cpu_shares

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U ${var.db_user}"]
    interval = "5s"
    timeout  = "3s"
    retries  = 5
  }

  restart = "unless-stopped"
}

# ---------- Compute tier: internal API ----------
# Attached to app_internal (so nginx can reach it) and db_internal (so it can
# reach postgres). Never attached to edge_net, so it is not reachable from
# outside the host.
resource "docker_image" "api" {
  name = var.api_image
}

resource "docker_container" "api" {
  count = var.api_replica_count
  name  = "${var.environment}-api-${count.index}"
  image = docker_image.api.image_id

  # http-echo as a stand-in "tiny API" - swap for a real image via var.api_image
  command = ["-listen=:5678", "-text=${var.environment} api ${count.index} ok"]

  env = [
    "DB_HOST=${docker_container.postgres.name}",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name = docker_network.app_internal.name
  }
  networks_advanced {
    name = docker_network.db_internal.name
  }

  memory  = var.api_memory_mb
  restart = "unless-stopped"

  depends_on = [docker_container.postgres]
}

# ---------- Edge tier: public reverse proxy ----------
# The ONLY service attached to edge_net, and the ONLY service with a published
# host port. Also attached to app_internal so it can proxy to the API - but it
# is never attached to db_internal, so it has no path to postgres.
resource "docker_image" "nginx" {
  name = var.nginx_image
}

locals {
  nginx_conf = <<-EOT
    events {}
    http {
      upstream api_upstream {
        %{for c in docker_container.api~}
        server ${c.name}:5678;
        %{endfor~}
      }
      server {
        listen 80;
        location / {
          proxy_pass http://api_upstream;
        }
        location /healthz {
          return 200 "ok\n";
        }
      }
    }
  EOT
}

resource "docker_container" "nginx" {
  name  = "${var.environment}-nginx"
  image = docker_image.nginx.image_id

  # Simpler and provider-portable than docker_config mounts on plain containers:
  # write the rendered conf to a local file Terraform manages, then bind-mount it.
  upload {
    content = local.nginx_conf
    file    = "/etc/nginx/nginx.conf"
  }

  ports {
    internal = 80
    external = var.edge_host_port
  }

  networks_advanced {
    name = docker_network.edge.name
  }
  networks_advanced {
    name = docker_network.app_internal.name
  }

  restart = "unless-stopped"

  depends_on = [docker_container.api]
}
