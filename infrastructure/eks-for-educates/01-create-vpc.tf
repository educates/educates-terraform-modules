resource "terraform_data" "delete_resources_after_vpc_deleted" {
  triggers_replace = {
    # Monitoring for public_network_acl_id will trigger this when public_network_acl_id changes.
    region       = var.aws_region
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command    = "/bin/bash ${path.module}/scripts/delete-volumes.sh ${self.triggers_replace.cluster_name} ${self.triggers_replace.region}"
    when       = destroy
    on_failure = continue
  }
  provisioner "local-exec" {
    command    = "/bin/bash ${path.module}/scripts/delete-cloudwatch-loggroups.sh ${self.triggers_replace.cluster_name} ${self.triggers_replace.region}"
    when       = destroy
    on_failure = continue
  }
}

resource "time_sleep" "wait_for_vpc_deletion" {
  # We use this to order destruction
  destroy_duration = "1s"

  depends_on = [terraform_data.delete_resources_after_vpc_deleted]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  # We use a dependency on triggers_replace on previous module instead of the var, to try to achieve better ordering
  name = "${var.cluster_name}-vpc"
  #  name = "${terraform_data.delete_resources_after_vpc_deleted.triggers_replace.cluster_name}-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
  }

  tags = local.tags

  depends_on = [time_sleep.wait_for_vpc_deletion]
}