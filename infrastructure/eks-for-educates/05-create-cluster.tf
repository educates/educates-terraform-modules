data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "terraform_data" "delete_resources_after_cluster_deleted" {
  triggers_replace = {
    # Monitoring for cluster_endpoint will trigger this when cluster_endpoint changes.
    vpc    = module.vpc.vpc_id
    region = var.aws_region
  }
  # Recommendation from here: https://github.com/hashicorp/terraform/issues/23679#issuecomment-886020367
  provisioner "local-exec" {
    command    = "/bin/bash ${path.module}/scripts/delete-elbs.sh ${self.triggers_replace.vpc} ${self.triggers_replace.region}"
    when       = destroy
    on_failure = continue # Can also be (abort)
  }
}

resource "time_sleep" "wait_for_cluster_deletion" {
  # We use this to order destruction
  destroy_duration = "30s"

  # We don't make module.eks depends on this because it gives problems, but rather resource aws_eks_addon.ebs-csi
  depends_on = [terraform_data.delete_resources_after_cluster_deleted]
}

locals {
  # We can use to configure the defaults when no value is specified
  node_groups = {
    for k, v in var.node_groups : k => merge(v, { iam_role_permissions_boundary = "arn:aws:iam::${var.aws_account_id}:policy/PowerUserPermissionsBoundaryPolicy" })
  }

  tags = merge({
    created_by = "edukates-eks-terraform"
  }, var.eks_additional_tags)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name                  = var.cluster_name
  cluster_version               = var.kubernetes_version
  iam_role_permissions_boundary = "arn:aws:iam::${var.aws_account_id}:policy/PowerUserPermissionsBoundaryPolicy"

  cluster_addons = {
    coredns = {
      most_recent = false # With most_recent=false, the default addon version for the specific kubernetes version will be selected
    }
    kube-proxy = {
      most_recent = false
    }
    vpc-cni = {
      most_recent = false
    }
  }

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = local.node_groups

  node_security_group_additional_rules = {
    ingress_kapp_controller_upstream = {
      description                   = "Allow nodes to talk to Kapp Controller upstream"
      protocol                      = "tcp" # "-1" for all
      from_port                     = 10350
      to_port                       = 10350
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_kapp_controller_downstream = {
      description                   = "Allow nodes to talk to Kapp Controller downstream"
      protocol                      = "tcp" # "-1" for all
      from_port                     = 32767
      to_port                       = 32767
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  #aws_cloudwatch_log_group.this[0]

  # aws-auth configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  aws_auth_users = var.aws_auth_users
  aws_auth_roles = var.aws_auth_roles

  # kms
  kms_key_administrators = concat(var.kms_key_administrators, [data.aws_iam_session_context.current.issuer_arn])
}

resource "aws_iam_policy" "additional" {
  name = "${var.cluster_name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.30.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
  role_permissions_boundary_arn = "arn:aws:iam::${var.aws_account_id}:policy/PowerUserPermissionsBoundaryPolicy"

  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  # addon_version            = "v1.22.0-eksbuild.2"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {
    "eks_addon" = "ebs-csi"
    "terraform" = "true"
  }
  depends_on = [
    module.eks,
    module.irsa-ebs-csi,
    time_sleep.wait_for_cluster_deletion
  ]
}


module "certmanager_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name                  = "svc.bot.route53.cert-manager-${var.cluster_name}"
  attach_cert_manager_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }

  role_permissions_boundary_arn = "arn:aws:iam::${var.aws_account_id}:policy/PowerUserPermissionsBoundaryPolicy"

  tags = local.tags

  depends_on = [
    module.eks
  ]
}

module "externaldns_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.30.0"

  role_name                  = "svc.bot.route53.external-dns-${var.cluster_name}"
  attach_external_dns_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }

  role_permissions_boundary_arn = "arn:aws:iam::${var.aws_account_id}:policy/PowerUserPermissionsBoundaryPolicy"

  tags = local.tags

  depends_on = [
    module.eks
  ]
}

# Some inspiration from: https://github.com/TykTechnologies/tyk-performance-testing/blob/main/modules/clouds/aws/main.tf
data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}