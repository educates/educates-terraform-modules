locals {
  network_ip_cidr_range  = "10.0.0.0/24"
  subnet_types           = ["pods", "services"]
  subnets_ip_cidr_ranges = ["10.1.0.0/16", "10.2.0.0/20"]
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 10.0"
  # Only execute this module if we are creating a dedicated VPC
  # count = var.dedicated_vpc ? 1 : 0

  project_id              = var.project_id
  network_name            = "${var.cluster_name}-vpc"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = "false"

  subnets = [
    {
      subnet_name           = "${var.cluster_name}-subnet"
      subnet_ip             = local.network_ip_cidr_range
      subnet_region         = "${var.region}"
      subnet_private_access = "true"
      #     subnet_flow_logs      = "true"
      #     description           = "This subnet has a description"
    }
  ]

  secondary_ranges = {
    "${var.cluster_name}-subnet" = [
      {
        range_name    = "range-${var.cluster_name}-${local.subnet_types[0]}"
        ip_cidr_range = local.subnets_ip_cidr_ranges[0]
      },
      {
        range_name    = "range-${var.cluster_name}-${local.subnet_types[1]}"
        ip_cidr_range = local.subnets_ip_cidr_ranges[1]
      },
    ]
  }


  # routes = [
  #   {
  #     name              = "egress-internet"
  #     description       = "route through IGW to access internet"
  #     destination_range = "0.0.0.0/0"
  #     tags              = "egress-inet"
  #     next_hop_internet = "true"
  #   },
  #   {
  #     name                   = "app-proxy"
  #     description            = "route through proxy to reach app"
  #     destination_range      = "10.50.10.0/24"
  #     tags                   = "app-proxy"
  #     next_hop_instance      = "app-proxy-instance"
  #     next_hop_instance_zone = "us-west1-a"
  #   },
  # ]
}

output "subnets" {
  value = module.vpc.subnets
}