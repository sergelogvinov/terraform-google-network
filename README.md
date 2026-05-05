# Terraform module for Google Cloud (GCP)

## Overview

## Usage Example

```hcl
module "network" {
  source = "github.com/sergelogvinov/terraform-google-network"

  project      = var.project
  region       = var.region
  cluster_name = "production"

  network_name  = "production"
  network_cidr  = ["172.17.0.0/16", "fd60:172:17::/48"]
  network_shift = 4

  allowlist_datacenters = ["2600:1900::/28"]
  allowlist_admins      = ["1.2.3.4/32"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 7.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_address.nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_address.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) | resource |
| [google_compute_external_vpn_gateway.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_external_vpn_gateway) | resource |
| [google_compute_firewall.common](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.common_cilium_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.common_dhcp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.common_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.controlplane](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.controlplane_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.controlplane_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.web](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.web_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_forwarding_rule.esp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_forwarding_rule.udp4500](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_forwarding_rule.udp500](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [google_compute_global_address.google](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_ha_vpn_gateway.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) | resource |
| [google_compute_network.network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_route.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_route) | resource |
| [google_compute_router.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_interface.hapeer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_interface) | resource |
| [google_compute_router_nat.private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_router_peer.hapeer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_peer) | resource |
| [google_compute_subnetwork.private](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.regional](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.regional_lb](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_vpn_gateway.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_gateway) | resource |
| [google_compute_vpn_tunnel.hapeer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) | resource |
| [google_compute_vpn_tunnel.peer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_vpn_tunnel) | resource |
| [google_service_networking_connection.googleapis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_compute_zones.region](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowlist_admins"></a> [allowlist\_admins](#input\_allowlist\_admins) | Allowlist for administrators | `list` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_allowlist_datacenters"></a> [allowlist\_datacenters](#input\_allowlist\_datacenters) | Allowlist for datacenters subnets | `list` | `[]` | no |
| <a name="input_allowlist_web"></a> [allowlist\_web](#input\_allowlist\_web) | Cloudflare subnets | `list` | <pre>[<br/>  "173.245.48.0/20",<br/>  "103.21.244.0/22",<br/>  "103.22.200.0/22",<br/>  "103.31.4.0/22",<br/>  "141.101.64.0/18",<br/>  "108.162.192.0/18",<br/>  "190.93.240.0/20",<br/>  "188.114.96.0/20",<br/>  "197.234.240.0/22",<br/>  "198.41.128.0/17",<br/>  "162.158.0.0/15",<br/>  "104.16.0.0/13",<br/>  "104.24.0.0/14",<br/>  "172.64.0.0/13",<br/>  "131.0.72.0/22"<br/>]</pre> | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | Google BGP ASN for dynamic peering | `number` | `64512` | no |
| <a name="input_bgp_stack"></a> [bgp\_stack](#input\_bgp\_stack) | Google BGP stack IPv4/IPv6/IPV4\_IPV6 for dynamic peering | `string` | `"IPV4_IPV6"` | no |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | n/a | `map(any)` | <pre>{<br/>  "all": {<br/>    "network_nat_enable": false,<br/>    "network_peer_enable": false<br/>  }<br/>}</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | A default cluster name | `any` | n/a | yes |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Local subnet rfc1918 | `list(string)` | <pre>[<br/>  "172.16.0.0/16",<br/>  "fd60:172:16::/48"<br/>]</pre> | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | n/a | `string` | `"main"` | no |
| <a name="input_network_peering"></a> [network\_peering](#input\_network\_peering) | n/a | `map(any)` | `{}` | no |
| <a name="input_network_shift"></a> [network\_shift](#input\_network\_shift) | Network number shift | `number` | `4` | no |
| <a name="input_project"></a> [project](#input\_project) | The project ID to host the cluster in | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to host the cluster in | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Defined Tags of resources | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_network_lb"></a> [network\_lb](#output\_network\_lb) | The lb network |
| <a name="output_network_nat"></a> [network\_nat](#output\_network\_nat) | The nat IPs |
| <a name="output_network_peering"></a> [network\_peering](#output\_network\_peering) | n/a |
| <a name="output_network_private"></a> [network\_private](#output\_network\_private) | The private network |
| <a name="output_network_public"></a> [network\_public](#output\_network\_public) | The public network |
| <a name="output_network_secgroup"></a> [network\_secgroup](#output\_network\_secgroup) | The Network Security Groups |
| <a name="output_networks"></a> [networks](#output\_networks) | Regional networks |
| <a name="output_project"></a> [project](#output\_project) | Region |
| <a name="output_region"></a> [region](#output\_region) | Region |
| <a name="output_zones"></a> [zones](#output\_zones) | Zones |
<!-- END_TF_DOCS -->