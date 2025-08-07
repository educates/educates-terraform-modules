# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

data "google_compute_zones" "this" {
  region  = var.region
  project = var.project_id
}

# resource "terraform_data" "delete_resources_after_cluster_deleted" {
#   triggers_replace = {
#     # Monitoring for cluster_endpoint will trigger this when cluster_endpoint changes.
#     network = module.vpc.network_self_link
#   }
#   # Recommendation from here: https://github.com/hashicorp/terraform/issues/23679#issuecomment-886020367
#   provisioner "local-exec" {
#     command    = "/bin/bash ${path.module}/scripts/delete-negs.sh ${self.triggers_replace.network}"
#     when       = destroy
#     on_failure = continue # Can also be (abort)
#   }
# }


# resource "time_sleep" "wait_for_cluster_deletion" {
#   # We use this to order destruction
#   destroy_duration = "30s"

#   # We don't make module.eks depends on this because it gives problems, but rather resource aws_eks_addon.ebs-csi
#   depends_on = [terraform_data.delete_resources_after_cluster_deleted]
# }

locals {
  # Ensure service account IDs are valid (6-30 chars, lowercase, alphanumeric + hyphens)
  # and unique by using a truncated cluster name with suffix
  cluster_name_safe = lower(replace(var.cluster_name, "_", "-"))
  base_account_id = substr(local.cluster_name_safe, 0, 30)
  cert_manager_account_id = substr("${local.cluster_name_safe}-cert-mgr", 0, 30)
  external_dns_account_id = substr("${local.cluster_name_safe}-ext-dns", 0, 30)

  # Zone configuration from VPC module
  zones = data.google_compute_zones.this.names
  zone  = slice(local.zones, 0, 1)

  # We can use to configure the defaults when no value is specified
  node_pools = [
    for ng in var.node_groups : merge(ng, { service_account = google_service_account.default.email })
  ]
}

resource "google_service_account" "default" {
  account_id   = local.base_account_id
  display_name = "Service Account created by TF for cluster ${var.cluster_name}"
  project      = var.project_id
}

output "node_pools" {
  value = local.node_pools
}

##
# We need to use the latest version of GKE, otherwise we get an error when creating the cluster
# with the default version
##
data "google_container_engine_versions" "gke_versions" {
  project       = var.project_id
  location       = var.region
  version_prefix = "${var.kubernetes_version}."
}

module "gke" {
  source                = "terraform-google-modules/kubernetes-engine/google"
  version               = "36.2.0"
  project_id            = var.project_id
  name                  = var.cluster_name
  region                = var.region
  zones                 = local.zone
  kubernetes_version    = data.google_container_engine_versions.gke_versions.latest_master_version # var.release_channel == null || var.release_channel == "UNSPECIFIED" ? local.master_version : var.kubernetes_version == "latest" ? null : var.kubernetes_version
  deletion_protection   = false # We want to be able to delete the clusters with TF
  network               = module.vpc.network_name
  subnetwork            = module.vpc.subnets_names[0]
  ip_range_pods         = module.vpc.subnets_secondary_ranges[0][0].range_name
  ip_range_services     = module.vpc.subnets_secondary_ranges[0][1].range_name
  configure_ip_masq     = true # --enable-ip-alias
  enable_shielded_nodes = true
  http_load_balancing   = false # Not defined in test cluster
  # network_policy             = false # Not defined in test cluster
  # horizontal_pod_autoscaling = true
  # filestore_csi_driver       = true
#  fleet_project          = var.fleet_project # optional
  identity_namespace     = "enabled"         # This sets workload-pool to [project_id].svc.id.goog
  release_channel        = "REGULAR"
  create_service_account = false
  service_account_name   = google_service_account.default.email
  # # node_metadata                       = "disable-legacy-endpoints=true"
  # default_max_pods_per_node           = 110
  # security_posture_vulnerability_mode = "VULNERABILITY_BASIC" # standard in configuration above
  # logging_enabled_components = [                              #  --logging=SYSTEM,WORKLOAD
  #   "SYSTEM_COMPONENTS",
  #   "WORKLOADS"
  # ]
  # monitoring_enable_managed_prometheus = true # --enable-managed-prometheus 
  # monitoring_enabled_components = [           # --monitoring=SYSTEM
  #   "SYSTEM_COMPONENTS"
  # ]

  # master_authorized_networks = [ # [] for --no-enable-master-authorized-networks
  #   {
  #     cidr_block   = module.vpc.subnets_ips[0]
  #     display_name = "VPC"
  #   },
  # ]

  node_pools = local.node_pools
  # [
  #   {
  #     name         = "default-node-pool"
  #     machine_type = "e2-medium"
  #     # node_locations = local.zone
  #     min_count          = 1
  #     max_count          = 6
  #     initial_node_count = 3
  #     # local_ssd_count    = 0
  #     # spot               = false
  #     disk_size_gb = 100
  #     disk_type    = "pd-balanced" # "pd-ssd"
  #     image_type   = "COS_CONTAINERD"
  #     # enable_gcfs        = false
  #     # enable_gvnic       = false
  #     # logging_variant    = "DEFAULT"
  #     auto_repair  = true
  #     auto_upgrade = true
  #     service_account = google_service_account.default.email
  #     preemptible     = false
  #     # strategy           = "SURGE"
  #     # max_surge          = 1
  #     # max_unavailable    = 0
  #   },
  # ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    default-node-pool = [
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

## Create 2 service GKE accounts for cert-manager and external-dns
resource "google_service_account" "cert-manager-gsa" {
  account_id   = local.cert_manager_account_id
  display_name = "Service Account created by TF for cert-manager for cluster ${var.cluster_name}"
  project      = var.project_id
}

resource "google_service_account" "external-dns-gsa" {
  account_id   = local.external_dns_account_id
  display_name = "Service Account created by TF for external-dns for cluster ${var.cluster_name}"
  project      = var.project_id
}

##
# TODO: Create finer grained roles for cert-manager and external-dns
##
# resource "google_project_iam_member" "cert-manager" {
#   project = var.project_id
#   role    = "roles/iam.workloadIdentityUser"
#   member  = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
# }
# resource "google_project_iam_member" "external-dns" {
#   project = var.project_id
#   role    = "roles/iam.workloadIdentityUser"
#   member  = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
# }

## Attach roles to the service accounts
resource "google_project_iam_binding" "cert-manager-and-external-dns-as-dns-admin" {
  project = var.project_id
  role    = "roles/dns.admin"
  members = [ 
    "serviceAccount:${google_service_account.cert-manager-gsa.email}",
    "serviceAccount:${google_service_account.external-dns-gsa.email}"
  ]
}

## Link the KSA to the GKE service accounts for cert-manager and external-dns
## This is needed to use Workload Identity
resource "google_service_account_iam_binding" "cert-manager-link-ksa-to-gsa" {
  service_account_id = google_service_account.cert-manager-gsa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [ "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]" ]
}

resource "google_service_account_iam_binding" "external-dns-link-ksa-to-gsa" {
  service_account_id = google_service_account.external-dns-gsa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = [ "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]" ]
}