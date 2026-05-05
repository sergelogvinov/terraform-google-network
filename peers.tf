
resource "google_compute_address" "peer" {
  count   = local.static_peering ? 1 : 0
  name    = "${var.cluster_name}-peer-${var.region}"
  project = var.project
  region  = var.region
}

resource "google_compute_vpn_gateway" "peer" {
  count   = local.static_peering ? 1 : 0
  name    = "${var.cluster_name}-peer-${var.region}"
  project = var.project
  region  = var.region
  network = google_compute_network.network.id
}

resource "google_compute_forwarding_rule" "esp" {
  count       = local.static_peering ? 1 : 0
  name        = "${var.cluster_name}-peer-${var.region}-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

resource "google_compute_forwarding_rule" "udp500" {
  count       = local.static_peering ? 1 : 0
  name        = "${var.cluster_name}-peer-${var.region}-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

resource "google_compute_forwarding_rule" "udp4500" {
  count       = local.static_peering ? 1 : 0
  name        = "${var.cluster_name}-peer-${var.region}-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.peer[0].address
  target      = google_compute_vpn_gateway.peer[0].self_link
  project     = var.project
  region      = var.region
}

locals {
  ipsec_tunnels = { for k in flatten([
    for peer, v in var.network_peering : [
      for i, ip in v.ip : {
        idx     = i
        peer    = peer
        name    = "${peer}-${i}"
        secret  = v.secret
        subnets = v.cidrs

        server_v4 = try(google_compute_address.peer[0].address, "")
        server_v6 = ""
        peer_v4   = length(split(".", ip)) > 1 ? ip : ""
        peer_v6   = length(split(":", ip)) > 1 ? ip : ""
      } if lookup(try(var.capabilities["all"], {}), "network_peer_enable", false)
    ] if length(lookup(v, "ip", [])) > 0
  ]) : k.name => k }
}

# output "network_peering" {
#   value = local.ipsec_tunnels
# }

resource "google_compute_vpn_tunnel" "peer" {
  for_each = !local.dynamic_peering ? local.ipsec_tunnels : {}
  name     = "${var.cluster_name}-peer-${var.region}-${each.key}"
  project  = var.project
  region   = var.region

  peer_ip            = each.value.peer_v4
  target_vpn_gateway = google_compute_vpn_gateway.peer[0].self_link

  ike_version              = 2
  shared_secret_wo         = each.value.secret
  shared_secret_wo_version = 1

  local_traffic_selector  = [local.network_cidr_v4]
  remote_traffic_selector = each.value.subnets

  # https://docs.cloud.google.com/network-connectivity/docs/vpn/concepts/supported-ike-ciphers
  cipher_suite {
    phase1 {
      encryption = ["AES-GCM-16-256", "AES-GCM-16-128"]
      integrity  = []
      prf        = ["PRF-HMAC-SHA2-256", "PRF-HMAC-SHA2-512"]
      dh         = ["Group-31", "Group-19"]
    }
    phase2 {
      encryption = ["AES-GCM-16-256", "AES-GCM-16-128"]
      integrity  = []
      pfs        = []
    }
  }

  depends_on = [
    google_compute_forwarding_rule.esp,
    google_compute_forwarding_rule.udp500,
    google_compute_forwarding_rule.udp4500,
  ]
}

resource "google_compute_route" "peer" {
  for_each = { for k in flatten([
    for link, v in local.ipsec_tunnels : [
      for i, subnet in v.subnets : {
        idx    = v.idx
        name   = "${link}-${i}"
        subnet = subnet
        tunnel = google_compute_vpn_tunnel.peer[link].id
    }] if !local.dynamic_peering
  ]) : k.name => k }

  name       = each.key
  network    = google_compute_network.network.id
  dest_range = each.value.subnet
  priority   = 1500

  next_hop_vpn_tunnel = each.value.tunnel
}
