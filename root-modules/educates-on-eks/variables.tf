###
# EKS Configuration
###

variable "aws_account_id" {
  description = "Account id of the AWS user. Can get with `aws sts get-caller-identity`"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "manage_aws_auth_configmap" {
  type = bool
}

variable "aws_auth_users" {
  type = list(object({
    groups   = list(string)
    userarn  = string
    username = string
  }))
  default = []
}

variable "aws_auth_roles" {
  type = list(object({
    groups   = list(string)
    rolearn  = string
    username = string
  }))
  default = []
}

variable "kms_key_administrators" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  description = "Cluster name to use"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of kubernetes cluster to create"
  type        = string
  default     = "1.31"

  validation {
    condition     = contains(["1.30", "1.31", "1.32"], var.kubernetes_version)
    error_message = "kubernetes_version must be between 1.30 and 1.32"
  }
}

variable "node_groups" {
  description = "Node groups for the cluster"
  type = map(object({
    name                          = string
    desired_size                  = optional(number, 3)
    max_size                      = optional(number, 6)
    min_size                      = optional(number, 2)
    instance_types                = optional(list(string), ["c6i.xlarge"])
    disk_size                     = optional(number, 100)
    use_custom_launch_template    = optional(bool, false)
    iam_role_permissions_boundary = optional(string)
  }))
  default = {
    one = {
      name = "node-group-1"
    },
  }
}

##
# Configuration for the Educates Installer
##
variable "educates_version" {
  description = "Educates version to use"
  type = string
  default = "3.2.2"
}

variable "TLD" {
  description = "Top Level Domain to use for services deployed in the cluster (cluster_name will be prepended for final wildcard_domain)"
  type        = string
}