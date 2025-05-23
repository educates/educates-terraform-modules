# Eks for Educates

This terraform module will create an EKS cluster suitable for Educates (3.x)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.22.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.36.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.22.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_certmanager_irsa_role"></a> [certmanager\_irsa\_role](#module\_certmanager\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.30.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.17.2 |
| <a name="module_externaldns_irsa_role"></a> [externaldns\_irsa\_role](#module\_externaldns\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.30.0 |
| <a name="module_irsa-ebs-csi"></a> [irsa-ebs-csi](#module\_irsa-ebs-csi) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.30.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.1.2 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_addon.ebs-csi](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/resources/eks_addon) | resource |
| [aws_iam_policy.additional](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/resources/iam_policy) | resource |
| [local_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [terraform_data.delete_resources_after_cluster_deleted](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.delete_resources_after_vpc_deleted](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [time_sleep.wait_for_cluster_deletion](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_vpc_deletion](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ebs_csi_policy](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/data-sources/iam_policy) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/5.22.0/docs/data-sources/iam_session_context) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | Account id of the AWS user. Can get with `aws sts get-caller-identity` | `string` | n/a | yes |
| <a name="input_aws_auth_roles"></a> [aws\_auth\_roles](#input\_aws\_auth\_roles) | n/a | <pre>list(object({<br/>    groups   = list(string)<br/>    rolearn  = string<br/>    username = string<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_users"></a> [aws\_auth\_users](#input\_aws\_auth\_users) | n/a | <pre>list(object({<br/>    groups   = list(string)<br/>    userarn  = string<br/>    username = string<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name to use | `string` | n/a | yes |
| <a name="input_create_kubeconfig"></a> [create\_kubeconfig](#input\_create\_kubeconfig) | if true, create local kubeconfig file | `bool` | `false` | no |
| <a name="input_eks_additional_tags"></a> [eks\_additional\_tags](#input\_eks\_additional\_tags) | Additional tags to add to EKS resources | `map(string)` | `{}` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | n/a | `list(string)` | `[]` | no |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | Kubeconfig file (full path) | `string` | `"kubeconfig.yaml"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version of kubernetes cluster to create | `string` | `"1.31"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | n/a | `bool` | `false` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Node groups for the cluster | <pre>map(object({<br/>    name                          = string<br/>    desired_size                  = optional(number, 3)<br/>    max_size                      = optional(number, 6)<br/>    min_size                      = optional(number, 2)<br/>    instance_types                = optional(list(string), ["c6i.xlarge"])<br/>    disk_size                     = optional(number, 100)<br/>    use_custom_launch_template    = optional(bool, false)<br/>    iam_role_permissions_boundary = optional(string)<br/>  }))</pre> | <pre>{<br/>  "one": {<br/>    "name": "node-group-1"<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_eks"></a> [eks](#output\_eks) | n/a |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | kubeconfig full path for the AWS EKS cluster |
| <a name="output_kubernetes"></a> [kubernetes](#output\_kubernetes) | Some inspiration from: https://github.com/TykTechnologies/tyk-performance-testing/blob/main/modules/clouds/aws/main.tf |
