
locals {
  zones = data.google_compute_zones.region.names

  static_peering  = length([for peer, v in var.network_peering : v.asn if lookup(v, "asn", 0) != 0]) == 0 ? lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) : false
  dynamic_peering = length([for peer, v in var.network_peering : v.asn if lookup(v, "asn", 0) != 0]) > 0 ? lookup(try(var.capabilities["all"], {}), "network_peer_enable", false) : false

  network_cidr_v4 = cidrsubnet(try(one([for ip in var.network_cidr : ip if length(split(".", ip)) > 1]), ""), 4, var.network_shift)
  network_cidr_v6 = cidrsubnet(try(one([for ip in var.network_cidr : ip if length(split(":", ip)) > 1]), ""), 8, var.network_shift * 8)
}

resource "google_compute_network" "network" {
  project                 = var.project
  name                    = var.network_name
  description             = "Project ${var.cluster_name}"
  routing_mode            = "REGIONAL"
  mtu                     = 1500
  auto_create_subnetworks = false

  enable_ula_internal_ipv6 = false
  internal_ipv6_range      = local.network_cidr_v6
}

resource "google_compute_router" "main" {
  name    = "${var.cluster_name}-route-${var.region}"
  project = var.project
  region  = var.region
  network = google_compute_network.network.name

  dynamic "bgp" {
    for_each = local.dynamic_peering ? [1] : []
    content {
      asn            = var.bgp_asn
      advertise_mode = "DEFAULT"
    }
  }
}

resource "google_compute_subnetwork" "regional_lb" {
  project     = var.project
  name        = "${var.cluster_name}-lb"
  region      = var.region
  description = "Load balancer subnet"
  network     = google_compute_network.network.id

  role          = "ACTIVE"
  stack_type    = "IPV4_ONLY"
  purpose       = "REGIONAL_MANAGED_PROXY"
  ip_cidr_range = cidrsubnet(cidrsubnet(local.network_cidr_v4, 4, 0), 2, 0)
}

resource "google_compute_subnetwork" "regional" {
  project     = var.project
  name        = "${var.cluster_name}-regional-${var.region}"
  region      = var.region
  description = "Regional subnet"
  network     = google_compute_network.network.id

  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "EXTERNAL"
  ip_cidr_range            = cidrsubnet(cidrsubnet(local.network_cidr_v4, 4, 0), 1, 1)
  private_ip_google_access = true
}

# resource "google_compute_subnetwork" "public" {
#   for_each    = { for idx, ad in local.zones : ad => idx }
#   project     = var.project
#   name        = "${var.cluster_name}-public-${each.key}"
#   region      = var.region
#   description = "Public subnet for zone ${each.key}"
#   network     = google_compute_network.network.id

#   stack_type               = "IPV4_IPV6"
#   ipv6_access_type         = "EXTERNAL"
#   ip_cidr_range            = cidrsubnet(local.network_cidr_v4, 4, each.value + 1)
#   private_ip_google_access = true
# }

resource "google_compute_subnetwork" "private" {
  for_each    = { for idx, ad in local.zones : ad => idx }
  project     = var.project
  name        = "${var.cluster_name}-private-${each.key}"
  region      = var.region
  description = "Private subnet for zone ${each.key}"
  network     = google_compute_network.network.id

  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "EXTERNAL"
  ip_cidr_range            = cidrsubnet(local.network_cidr_v4, 4, each.value + 4)
  private_ip_google_access = true
}

resource "google_compute_global_address" "google" {
  name          = "${var.cluster_name}-private-google"
  purpose       = "VPC_PEERING"
  ip_version    = "IPV4"
  address       = cidrhost(cidrsubnet(local.network_cidr_v4, 4, 15), 0)
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.network.id
}

resource "google_service_networking_connection" "googleapis" {
  network                 = google_compute_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google.name]
}
