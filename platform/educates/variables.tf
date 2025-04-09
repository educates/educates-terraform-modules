variable "educates_app" {
  type = object({
    namespace   = optional(string, "package-installs")
    sync_period = optional(string, "8760h0m0s")
  })
  default = {
  }

  validation {
    condition     = can(regex("^(\\d{1,4})h(\\d{1,2})m(\\d{1,2})s", var.educates_app.sync_period))
    error_message = "educates_app.sync_period must be a valid kapp-controller sync period (e.g. 12h0m0s or 1h or 10m) and always greater that 30s"
  }
}

variable "educates_config" {
  type = object({
    installer_oci_image    = optional(string, "ghcr.io/educates/educates-installer")
    version                = optional(string, "3.2.2")
    config_file            = optional(string, "educates-app-config.yaml")
    config_is_to_be_merged = optional(bool, true)
    install                = optional(bool, true)
  })
  default = {
  }
}

variable "wildcard_domain" {
  description = "Wildcard domain to use for services deployed in the cluster"
  type        = string
}

variable "infrastructure_provider" {
  description = "Infrastructure provider"
  type        = string

  validation {
    condition     = contains(["aws", "gcp"], var.infrastructure_provider)
    error_message = "Invalid infrastructure_provider"
  }
}

# TODO: Make these into a struct
#####
# AWS
#####
variable "aws_config" {
  type = object({
    account_id   = string
    cluster_name = string
    region       = string
    dns_zone     = string
  })
  default = {
    account_id   = ""
    cluster_name = ""
    region       = ""
    dns_zone     = ""
  }
}

#####
# GCP
#####
variable "gcp_config" {
  type = object({
    cluster_name = string
    project      = string
    dns_zone     = string
  })
  default = {
    cluster_name = ""
    project      = ""
    dns_zone     = ""
  }
}
