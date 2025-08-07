###
# GKE (Google Kubernetes Engine) Configuration
###

variable "project_id" {
  description = "Account id of the GCP user"
  type        = string
}

variable "region" {
  description = "compute region where this cluster will live"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of kubernetes cluster to create"
  type        = string
  default     = "1.33"

  validation {
    condition     = contains(["1.30", "1.31", "1.32", "1.33"], var.kubernetes_version)
    error_message = "kubernetes_version must be between 1.30 and 1.33"
  }
}

variable "cluster_name" {
  description = "Cluster name to use"
  type        = string
}

# variable "fleet_project" {
#   description = "Project to use for the fleet"
#   type        = string
# }

# variable "dedicated_vpc" {
#   description = "Create a dedicated VPC for this cluster?"
#   type = bool
#   default = false
# }

variable "node_groups" {
  description = "Node groups for the cluster"
  type = list(object({
    name               = string
    machine_type       = optional(string, "e2-medium")
    min_count          = optional(number, 3)
    max_count          = optional(number, 3)
    initial_node_count = optional(number, 3)
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-balanced") # "pd-standard", "pd-balanced", "pd-ssd"
    image_type         = optional(string,"COS_CONTAINERD")
    auto_repair        = optional(bool, true)
    auto_upgrade       = optional(bool, true)
    preemptible        = optional(bool, false)
    service_account    = optional(string, "default")
  }))
    #     node_locations     = "us-central1-b,us-central1-c" # local.zone
    #     local_ssd_count    = 0
    #     spot               = false
    #     enable_gcfs        = false
    #     enable_gvnic       = false
    #     logging_variant    = "DEFAULT"
    #     strategy           = "SURGE"
    #     max_surge          = 1
    #     max_unavailable    = 0
  default = [
    {
      name="default-node-pool"
    }
  ]
}

# variable "gke_additional_tags" {
#   description = "Additional tags to add to GKE resources"
#   type        = map(string)
#   default     = {}
# }

variable "kubeconfig_file" {
  description = "Kubeconfig file (full path). Will default to kubeconfig_<cluster_name>.yaml in the current directory if not set"
  type        = string
  default     = ""
}
