###
# GKE Configuration
###

variable "project_id" {
  description = "GCP project"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name to use"
  type        = string
}

variable "node_groups" {
  description = "Node groups for the cluster"
  type = list(object({
    name               = string
    machine_type       = optional(string, "e2-medium")
    min_count          = optional(number, 1)
    max_count          = optional(number, 6)
    initial_node_count = optional(number, 3)
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-balanced") # "pd-standard", "pd-balanced", "pd-ssd"
    image_type         = optional(string,"COS_CONTAINERD")
    auto_repair        = optional(bool, true)
    auto_upgrade       = optional(bool, true)
    preemptible        = optional(bool, false)
  }))
  default = [
    {
      name="default-node-pool"
    }
  ]
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

variable "kubeconfig_file" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = ""
}

##
# Configuration for the Educates Installer
##
variable "deploy_educates" {
  description = "Whether to deploy/install Educates platform onto the cluster"
  type        = bool
  default     = true
}

variable "educates_version" {
  description = "Educates version to use"
  type = string
  default = "3.3.2"
}

variable "TLD" {
  description = "Top Level Domain to use for services deployed in the cluster (cluster_name will be prepended for final wildcard_domain)"
  type        = string
}
