###
# AWS EKS Configuration
###

variable "aws_account_id" {
  description = "Account id of the AWS user. Can get with `aws sts get-caller-identity`"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of kubernetes cluster to create"
  type        = string
  default     = "1.32"
}

variable "cluster_name" {
  description = "Cluster name to use"
  type        = string
}

variable "ami_type" {
  description = "AMI type to use for the node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
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

variable "eks_additional_tags" {
  description = "Additional tags to add to EKS resources"
  type        = map(string)
  default     = {}
}

variable "kubeconfig_file" {
  description = "Kubeconfig file (full path)"
  type        = string
  default     = "kubeconfig.yaml"
}

variable "create_kubeconfig" {
  description = "if true, create local kubeconfig file"
  type        = bool
  default     = false
}

variable "manage_aws_auth_configmap" {
  type    = bool
  default = false
}

variable "aws_auth_roles" {
  type = list(object({
    groups   = list(string)
    rolearn  = string
    username = string
  }))
  default = []
}

variable "aws_auth_users" {
  type = list(object({
    groups   = list(string)
    userarn  = string
    username = string
  }))
  default = []
}

variable "kms_key_administrators" {
  type    = list(string)
  default = []
}