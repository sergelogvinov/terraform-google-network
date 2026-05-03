
output "project" {
  description = "Region"
  value       = var.project
}

output "region" {
  description = "Region"
  value       = var.region
}

output "zones" {
  description = "Zones"
  value       = local.zones
}

output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}

output "networks" {
  description = "Regional networks"
  value = {
    "${var.region}" = {
      name    = var.network_name
      cidr_v4 = local.network_cidr_v4
      cidr_v6 = local.network_cidr_v6
      peer_v4 = try(google_compute_address.peer[0].address, "")
    }
  }
}

output "network_lb" {
  description = "The lb network"
  value = { for idx, zone in local.zones : zone => {
    self_link  = google_compute_subnetwork.regional_lb.self_link
    network_id = google_compute_network.network.id
    subnet_id  = google_compute_subnetwork.regional_lb.id

    cidr_v4    = google_compute_subnetwork.regional_lb.ip_cidr_range
    cidr_v6    = ""
    gateway_v4 = google_compute_subnetwork.regional_lb.gateway_address
    gateway_v6 = ""
    mtu        = google_compute_network.network.mtu
    tier       = google_compute_subnetwork.regional_lb.ipv6_access_type == "EXTERNAL" ? "PREMIUM" : "STANDARD"
  } }
}

output "network_public" {
  description = "The public network"
  value = { for idx, zone in local.zones : zone => {
    self_link  = google_compute_subnetwork.regional.self_link
    network_id = google_compute_network.network.id
    subnet_id  = google_compute_subnetwork.regional.id

    cidr_v4    = google_compute_subnetwork.regional.ip_cidr_range
    cidr_v6    = cidrsubnet(google_compute_subnetwork.regional.external_ipv6_prefix, 0, 0)
    gateway_v4 = google_compute_subnetwork.regional.gateway_address
    gateway_v6 = ""
    mtu        = google_compute_network.network.mtu
    tier       = google_compute_subnetwork.regional.ipv6_access_type == "EXTERNAL" ? "PREMIUM" : "STANDARD"
  } }
}

output "network_private" {
  description = "The private network"
  value = { for idx, zone in local.zones : zone => {
    self_link  = google_compute_subnetwork.private[zone].self_link
    network_id = google_compute_network.network.id
    subnet_id  = google_compute_subnetwork.private[zone].id

    cidr_v4    = google_compute_subnetwork.private[zone].ip_cidr_range
    cidr_v6    = cidrsubnet(google_compute_subnetwork.private[zone].external_ipv6_prefix, 0, 0)
    gateway_v4 = google_compute_subnetwork.private[zone].gateway_address
    gateway_v6 = ""
    mtu        = google_compute_network.network.mtu
    tier       = google_compute_subnetwork.private[zone].ipv6_access_type == "EXTERNAL" ? "PREMIUM" : "STANDARD"
  } }
}

output "network_nat" {
  description = "The nat IPs"
  value = {
    "${var.region}" = {
      ip_v4 = try(google_compute_address.nat[0].address, "")
    }
  }
}

output "network_secgroup" {
  description = "The Network Security Groups"
  value = {
    common       = "${var.network_name}-common"
    controlplane = "${var.network_name}-controlplane"
    web          = "${var.network_name}-web"
  }
}

# output "network_peering" {
#   value = { for k, v in local.ipsec_tunnels : k => {
#     server = {
#       asn  = v.server_asn
#       ip4  = v.server_v4
#       ip6  = v.server_v6
#       p2p4 = v.server_p2p_v4
#       p2p6 = v.server_p2p_v6 != "" ? scaleway_s2s_vpn_connection.peer[k].bgp_session_ipv6[0].private_ip : null
#     }
#     client = {
#       asn  = v.peer_asn
#       ip4  = v.peer_v4
#       ip6  = v.peer_v6
#       p2p4 = v.peer_p2p_v4
#       p2p6 = v.peer_p2p_v6 != "" ? scaleway_s2s_vpn_connection.peer[k].bgp_session_ipv6[0].peer_private_ip : null
#     }
#     }
#   }
# }
