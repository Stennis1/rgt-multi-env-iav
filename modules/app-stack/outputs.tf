output "nginx_container_name" {
  value = docker_container.nginx.name
}

output "api_container_names" {
  value = [for c in docker_container.api : c.name]
}

output "postgres_container_name" {
  value = docker_container.postgres.name
}

output "edge_url" {
  value = "http://localhost:${var.edge_host_port}"
}

output "networks" {
  value = {
    edge = docker_network.edge.name
    app  = docker_network.app_internal.name
    db   = docker_network.db_internal.name
  }
}
