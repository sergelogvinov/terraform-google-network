
resource "google_compute_firewall" "common" {
  for_each    = toset(var.network_cidr)
  project     = var.project
  name        = "${var.cluster_name}-common-v${length(split(".", each.value)) > 1 ? "4" : "6"}"
  network     = var.network_name
  description = "Allow common traffic"
  priority    = 900
  direction   = "INGRESS"
  source_ranges = length(split(".", each.value)) > 1 ? [each.value] : flatten([each.value,
    cidrsubnet(google_compute_subnetwork.regional.external_ipv6_prefix, 0, 0),
    [for sub in google_compute_subnetwork.private : cidrsubnet(sub.external_ipv6_prefix, 0, 0)]]
  )
  target_tags = ["${var.cluster_name}-common"]

  allow {
    protocol = length(split(".", each.value)) > 1 ? "icmp" : "58" # ipv6-icmp
  }

  allow {
    protocol = "tcp"
    ports    = ["4240", "10250", "50000", "50001"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "common_dhcp" {
  project       = var.project
  name          = "${var.cluster_name}-dhcp-v6"
  network       = var.network_name
  description   = "Allow dhcp traffic"
  priority      = 910
  direction     = "INGRESS"
  source_ranges = ["fe80::/10"]
  target_tags   = ["${var.cluster_name}-common"]

  allow {
    protocol = "udp"
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "common_health_check" {
  for_each = {
    v4 : ["169.254.169.254", "35.191.0.0/16", "130.211.0.0/22"]
  }
  project       = var.project
  name          = "${var.cluster_name}-common-health-${each.key}"
  network       = var.network_name
  description   = "Allow common health check"
  priority      = 950
  direction     = "INGRESS"
  source_ranges = each.value
  target_tags   = ["${var.cluster_name}-common"]

  allow {
    protocol = "tcp"
    ports    = ["50000", "4240"]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "common_cilium_health_check" {
  for_each = { for k, v in {
    v6 : compact([for sub in var.allowlist_datacenters : sub if length(split(":", sub)) > 1])
  } : k => v if length(v) > 0 }
  project       = var.project
  name          = "${var.cluster_name}-common-cilium-health-v6"
  network       = var.network_name
  description   = "Allow common health check"
  priority      = 950
  direction     = "INGRESS"
  source_ranges = each.value
  target_tags   = ["${var.cluster_name}-common"]

  allow {
    protocol = "58" # ipv6-icmp
  }

  allow {
    protocol = "tcp"
    ports    = ["4240"]
  }

  depends_on = [google_compute_network.network]
}

# Controlplane

resource "google_compute_firewall" "controlplane" {
  for_each    = toset(var.network_cidr)
  project     = var.project
  name        = "${var.cluster_name}-controlplane-v${length(split(".", each.value)) > 1 ? "4" : "6"}"
  network     = var.network_name
  description = "Allow controlplane services"
  priority    = 1000
  direction   = "INGRESS"
  source_ranges = length(split(".", each.value)) > 1 ? [each.value] : flatten([each.value,
    cidrsubnet(google_compute_subnetwork.regional.external_ipv6_prefix, 0, 0),
    [for sub in google_compute_subnetwork.private : cidrsubnet(sub.external_ipv6_prefix, 0, 0)]]
  )
  target_tags = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "tcp"
    ports    = ["2379", "2380", "6443", "50001"]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "controlplane_admin" {
  for_each = { for k, v in {
    v4 : compact([for sub in var.allowlist_admins : sub if length(split(".", sub)) > 1])
    v6 : compact([for sub in var.allowlist_admins : sub if length(split(":", sub)) > 1])
  } : k => v if length(v) > 0 }
  project       = var.project
  name          = "${var.cluster_name}-controlplane-admin"
  network       = var.network_name
  description   = "Allow admin console"
  priority      = 1001
  direction     = "INGRESS"
  source_ranges = each.value
  target_tags   = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "icmp" # length(split(".", each.value)) > 1 ? "icmp" : "58" # ipv6-icmp
  }

  allow {
    protocol = "tcp"
    ports    = ["6443", "50000"]
  }

  depends_on = [google_compute_network.network]
}

#
# https://cloud.google.com/load-balancing/docs/health-check-concepts
#
resource "google_compute_firewall" "controlplane_health_check" {
  for_each = {
    v4 : ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
    v6 : ["2600:1901:8001::/48", "2600:2d00:1:b029::/64"]
  }
  project       = var.project
  name          = "${var.cluster_name}-controlplane-health-${each.key}"
  network       = var.network_name
  description   = "Allow Internal LB health check"
  priority      = 1100
  direction     = "INGRESS"
  source_ranges = each.value
  target_tags   = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "tcp"
    ports    = ["6443", "50000"]
  }

  depends_on = [google_compute_network.network]
}

# Web

resource "google_compute_firewall" "web" {
  project       = var.project
  name          = "${var.cluster_name}-web"
  network       = var.network_name
  description   = "Allow web"
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = var.allowlist_web
  target_tags   = ["${var.cluster_name}-web"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

#
# https://cloud.google.com/load-balancing/docs/health-check-concepts
#
resource "google_compute_firewall" "web_health_check" {
  for_each = {
    v4 : ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
    v6 : ["2600:1901:8001::/48", "2600:2d00:1:b029::/64"]
  }
  project       = var.project
  name          = "${var.cluster_name}-web-health-${each.key}"
  network       = var.network_name
  description   = "Allow web health check"
  priority      = 1100
  direction     = "INGRESS"
  source_ranges = each.value
  target_tags   = ["${var.cluster_name}-web"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}
