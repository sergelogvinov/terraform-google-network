
locals {
  stacks = ["v4", "v6"]

  ipsec_tunnels_p2p = { for k in flatten([
    for peer, v in var.network_peering : {
      name = peer
      v4   = one([for ip in lookup(v, "p2p", []) : ip if length(split(".", ip)) > 1])
      v6   = one([for ip in lookup(v, "p2p", []) : ip if length(split(":", ip)) > 1])
      asn  = lookup(v, "asn", 0)
    }
  ]) : k.name => k }

  ipsec_tunnels_ha = { for k in flatten([
    for peer, v in var.network_peering : [
      for i, ip in v.ip : [
        for iface, vpn in google_compute_ha_vpn_gateway.peer[0].vpn_interfaces : {
          idx     = i
          peer    = peer
          name    = "${peer}-${i}-${iface}"
          secret  = v.secret
          subnets = v.cidrs

          server_asn    = var.bgp_asn
          server_v4     = vpn.ip_address
          server_v6     = ""
          server_p2p_v4 = local.ipsec_tunnels_p2p[peer].v4 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[peer].v4, 3, i), 2 * iface + v.p2p_side) : ""
          server_p2p_v6 = local.ipsec_tunnels_p2p[peer].v6 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[peer].v6, 3, i), 4 * iface + v.p2p_side) : ""

          peer_asn    = v.asn
          peer_v4     = length(split(".", ip)) > 1 ? ip : ""
          peer_v6     = length(split(":", ip)) > 1 ? ip : ""
          peer_p2p_v4 = local.ipsec_tunnels_p2p[peer].v4 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[peer].v4, 3, i), 2 * iface + 1 - v.p2p_side) : ""
          peer_p2p_v6 = local.ipsec_tunnels_p2p[peer].v6 != null ? cidrhost(cidrsubnet(local.ipsec_tunnels_p2p[peer].v6, 3, i), 4 * iface + 1 - v.p2p_side) : ""
        } if iface == i
      ]
    ] if length(lookup(v, "ip", [])) > 0 && local.dynamic_peering]
  ) : k.name => k }
}

# output "network_peering" {
#   value = local.ipsec_tunnels_ha
# }

resource "google_compute_ha_vpn_gateway" "peer" {
  count   = local.dynamic_peering ? 1 : 0
  name    = "${var.cluster_name}-peer-${var.region}"
  project = var.project
  region  = var.region
  network = google_compute_network.network.id

  stack_type = var.bgp_stack
}

resource "google_compute_external_vpn_gateway" "peer" {
  for_each = local.dynamic_peering ? { for k, v in var.network_peering : k => v if length(lookup(v, "ip", [])) > 0 } : {}
  name     = "${var.cluster_name}-peer-${var.region}-${each.key}"
  project  = var.project

  redundancy_type = length(each.value.ip) > 1 ? "TWO_IPS_REDUNDANCY" : "SINGLE_IP_INTERNALLY_REDUNDANT"

  dynamic "interface" {
    for_each = { for i, ip in each.value.ip : i => ip if ip != "" }
    content {
      id         = interface.key
      ip_address = interface.value
    }
  }
}

resource "google_compute_vpn_tunnel" "hapeer" {
  for_each = local.dynamic_peering ? local.ipsec_tunnels_ha : {}
  name     = "${var.cluster_name}-peer-${var.region}-${each.key}"
  project  = var.project
  region   = var.region

  router                          = google_compute_router.main.id
  vpn_gateway                     = google_compute_ha_vpn_gateway.peer[0].id
  peer_external_gateway           = google_compute_external_vpn_gateway.peer[each.value.peer].id
  peer_external_gateway_interface = each.value.idx
  vpn_gateway_interface           = each.value.idx

  ike_version              = 2
  shared_secret_wo         = each.value.secret
  shared_secret_wo_version = 1

  # local_traffic_selector  = ["0.0.0.0/0"]
  # remote_traffic_selector = ["0.0.0.0/0"]

  # https://docs.cloud.google.com/network-connectivity/docs/vpn/concepts/supported-ike-ciphers
  cipher_suite {
    phase1 {
      encryption = ["AES-GCM-16-256", "AES-GCM-16-128"]
      integrity  = []
      prf        = ["PRF-HMAC-SHA2-256", "PRF-HMAC-SHA2-512"]
      dh         = ["Group-31", "Group-19", "Group-16", "Group-14"]
    }
    phase2 {
      encryption = ["AES-GCM-16-256", "AES-GCM-16-128"]
      integrity  = []
      pfs        = []
    }
  }
}

resource "google_compute_router_interface" "hapeer" {
  for_each = local.dynamic_peering ? { for k in flatten([
    for name, tunnel in local.ipsec_tunnels_ha : [
      for stack in local.stacks : [
        {
          link       = "${name}-${stack}"
          name       = name
          server_p2p = stack == "v4" ? "${tunnel.server_p2p_v4}/31" : "${tunnel.server_p2p_v6}/126"
        }
      ]
    ]
  ]) : k.link => k } : {}

  name    = "${var.cluster_name}-peer-${var.region}-${each.key}"
  project = var.project
  region  = var.region

  router     = google_compute_router.main.name
  ip_range   = each.value.server_p2p
  vpn_tunnel = google_compute_vpn_tunnel.hapeer[each.value.name].name
}

resource "google_compute_router_peer" "hapeer" {
  for_each = local.dynamic_peering ? { for k in flatten([
    for name, tunnel in local.ipsec_tunnels_ha : [
      for stack in local.stacks : [
        {
          link     = "${name}-${stack}"
          name     = name
          stack    = stack
          peer_p2p = stack == "v4" ? tunnel.peer_p2p_v4 : tunnel.peer_p2p_v6
          peer_asn = tunnel.peer_asn
          range    = stack == "v4" ? local.network_cidr_v4 : local.network_cidr_v6
        }
      ]
    ]
  ]) : k.link => k } : {}

  name    = "${var.cluster_name}-peer-${var.region}-${each.key}"
  project = var.project
  region  = var.region

  enable_ipv4     = each.value.stack == "v4" ? true : false
  enable_ipv6     = each.value.stack == "v6" ? true : false
  router          = google_compute_router.main.name
  peer_ip_address = each.value.peer_p2p
  peer_asn        = each.value.peer_asn

  advertised_route_priority = 100
  interface                 = google_compute_router_interface.hapeer[each.key].name

  advertise_mode = "CUSTOM"
  advertised_ip_ranges {
    range = each.value.range
  }
}
