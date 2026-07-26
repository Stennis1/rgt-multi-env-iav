# Three networks per environment, not two, is the deliberate design choice here.
#
#   edge_net   <-> nginx only, this is the one network with a published host port.
#   app_net    <-> nginx + api. This is how the edge tier reaches the compute tier.
#   db_net     <-> api + postgres. nginx is NEVER attached to this network.
#
# Result: nginx has no route to postgres at all - not "blocked by a rule", but
# literally no network path, which is a stronger and easier-to-verify claim than
# a security-group ALLOW/DENY list would give you. This is the Docker analog of
# splitting a VPC into a public subnet, an app-tier private subnet, and a
# db-tier private subnet with distinct security groups.

resource "docker_network" "edge" {
  name = "${var.environment}-edge-net"
}

resource "docker_network" "app_internal" {
  name = "${var.environment}-app-net"
  # no published ports ever touch this network
}

resource "docker_network" "db_internal" {
  name = "${var.environment}-db-net"
  # no published ports ever touch this network
}
