
resource "google_compute_address" "peer" {
  count   = lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) ? 1 : 0
  name    = "${var.cluster_name}-peer-${var.region}"
  project = var.project
  region  = var.region
}

resource "google_compute_vpn_gateway" "peer" {
  count   = lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) ? 1 : 0
  name    = "${var.cluster_name}-peer-${var.region}"
  project = var.project
  region  = var.region
  network = google_compute_network.network.id
}

resource "google_compute_forwarding_rule" "esp" {
  count       = lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) ? 1 : 0
  name        = "${google_compute_vpn_gateway.peer[0].name}-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

resource "google_compute_forwarding_rule" "udp500" {
  count       = lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) ? 1 : 0
  name        = "${google_compute_vpn_gateway.peer[0].name}-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

resource "google_compute_forwarding_rule" "udp4500" {
  count       = lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) ? 1 : 0
  name        = "${google_compute_vpn_gateway.peer[0].name}-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

locals {
  ipsec_tunnels = { for k in flatten([
    for peer, v in var.network_peering : {
      name   = "${peer}-${var.region}"
      region = var.region

      server_v4     = google_compute_address.peer[0].address
      server_v6     = ""
      peer_v4       = length(split(".", v.ip)) > 1 ? v.ip : null
      peer_v6       = length(split(":", v.ip)) > 1 ? v.ip : null
      static_routes = v.cidrs
      shared_secret = v.secret
    } if lookup(try(var.capabilities["all"], {}), "network_peer_enable", false)
    ]
  ) : k.name => k }
}

output "network_peering" {
  value = local.ipsec_tunnels
}

resource "google_compute_vpn_tunnel" "peer" {
  for_each = local.ipsec_tunnels
  name     = each.key
  project  = var.project
  region   = var.region

  peer_ip = each.value.peer_v4

  ike_version   = 2
  shared_secret = each.value.shared_secret

  target_vpn_gateway      = google_compute_vpn_gateway.peer[0].self_link
  local_traffic_selector  = [local.network_cidr_v4]
  remote_traffic_selector = each.value.static_routes

  depends_on = [
    google_compute_forwarding_rule.esp,
    google_compute_forwarding_rule.udp500,
    google_compute_forwarding_rule.udp4500,
  ]
}

resource "google_compute_route" "peer" {
  for_each = { for k in flatten([
    for peer, v in local.ipsec_tunnels : [
      for i, cidr in v.static_routes : {
        name   = "${peer}-${i}"
        cidr   = cidr
        tunnel = google_compute_vpn_tunnel.peer[peer].id
    }]
  ]) : k.name => k }

  name       = each.key
  network    = google_compute_network.network.id
  dest_range = each.value.cidr
  priority   = 1500

  next_hop_vpn_tunnel = each.value.tunnel
}
