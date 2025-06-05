# Educates Terraform modules

Terraform modules used for Educates cluster management

This repository provides a set of reusable Terraform modules to create [Educates Infrastructure](./infrastructure/) such as an EKS or GKE cluster to be used for Educates, with all the typical pre-requisites satisfied, and there's modules to create the [Educates Platform](./platform/) on a cluster.

There's also [root-modules](./root-modules/) that serve as reference implementations showing how to get a full [Educates](educates.dev) installation.
These are not versioned.

- [gke](./root-modules/educates-on-gke/)
- [eks](./root-modules/educates-on-eks/)

## Configuration examples

In each of the root modules you will see `examples` directories.
In them you will see example configurations for typical scenarios.

You will notice that the examples have placeholders `{{parameter_name}}` for sensitive parameters or variables specific to your environment.

It is expected that you will have access to,
and appropriate permissions in the associated cloud IaaS provider account to provision dns, network, compute and k8s resources.

The following are descriptions of the necessary parameters:

### Common

-   `kubernetes_version` is the k8s version, default of `1.32`.
    Note the version must be supported by the IaaS provider.

-   `cluster_name` is the name of the cluster, as referenced in your environment.

-   `deploy_educates` defaults to `true`.
    You can choose to deploy only the K8s cluster,
    useful in situations where you might want to test the Educates cli installation process.

-   `educates_ingress_domain` is the subdomain (or could be root domain) assigned to your educates deployment ingress.
    Educates will automatically manage the dynamic subdomain prefixes and associated paths for training portal and workshop session ingress.

### EKS

Minimum requirements:

-   `aws_region` is the region where the cluster will be provisioned.
    This is normally set in the environment with the `AWS_REGION` variable.

-   `aws_account_id` is the AWS account id under which the cluster will be provisioned and managed.

-   Implicit terraform user AWS caller IAMS account will need necessary admin permissions on
    the AWS account to create network, cluster, compute and storage resources, and
    will be implicitly granted the EKS cluster admin access.

Optional:

-   The `aws_auth_users`, `aws_auth_roles` and `kms_key_administrators` are examples of optional features
    where tailoring access and encryption.
   `aws_auth_users` and `aws_auth_roles` are used if wanting to enable the `aws-auth` configmap

-   `iams_principal` is an AWS IAMS user,
    and used as an example of where other AWS IAMS users may be added to the AWS auth map
    for access to the cluster.

-   `TerraformPlanApply` role is an example where adding a role specifically for Terraform,
    as added to the `aws-auth` configmap.

-   `AWSReservedSSO_AdministratorAccess` role is an example where adding a role specifically for Terraform,
    as added to the `aws-auth` configmap.

### GKE

-   `gcp_region` is the region where the cluster will be provisioned.
    This is normally set in the environment with the `GCLOUD_REGION` variable.

-   `gcp_project_id` is the GCP project under which the cluster will be provisioned and managed.

### Ingress requirements

Note that the `educates_ingress_domain` (AKA `TLD`) configuration must also be configured with a DNS zone in the
associated cloud dns provider.

### Kubeconfig

After the cluster is provisioned,
a kubeconfig file is provided for you in the root module directory from where you ran the terraform plan.

It is named in the form `kubeconfig-{{cluster_name}}-token.yaml`.

Assuming you maintain your GKE or AWS IAM user session,
you can set the KUBECONFIG in the environment,
and access with the `kubectl` or other derived k8s client commands.

### Contributions/Improvements

If you have suggested improvements,
or some common configurations you want to share,
[submit a PR](#release-a-module).  We'll review and potentially add it.

## Gitops configuration

Educates supports use of Gitops approach to deploy training portals and workshops.
You can see more about it [here](https://github.com/educates/educates-workshop-gitops-configurer).

The terraform modules do not yet have the gitops configurable added,
check back, we'll get it added soon.

## Release a module

This repository uses https://github.com/techpivot/terraform-module-releaser to have GitHub Actions releasing the modules.
See configuration at [terraform-module-releaser.yaml](./.github/workflows/terraform-module-releaser.yaml)

To release:
- Create a PR from your branch to main with the following starting text at PR name or commit contained in the PR. It follows [Conventional commits](https://www.conventionalcommits.org/en/v1.0.0/):
    - To create a `major` release use `major change`,`major update` or `breaking change`
    - To create a minor release use `feat`,`feature`
    - To create a patch release use `fix`,`chore`,`docs`

__NOTE__: Initial release will not need to adhere to this rule

Examples:
- test: debugging outputs with changed module
- fix: improve example variable
- feat: add another demo module

## Contributions and Licensing guidelines

See the following:

- [Contribution guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [License](./LICENSE)

Note they are the same as the [Educates Training Platform](https://github.com/educates/educates-training-platform) OSS guidelines.

## TODO

- [x] Make this into educates-terraform-modules GitHub repository
- [x] Adopt best practices for module naming as suggested in https://github.com/techpivot/terraform-module-releaser
- [x] Make the modules releasable via https://github.com/techpivot/terraform-module-releaser
- [x] Validate eks-for-educates module
- [x] EKS root module
- [ ] Adopt terraform-docs for modules https://terraform-docs.io/
- [x] token-sa-kubeconfig module (working with EKS and GKE)
- [x] educates-gitops module
- [ ] sample root-module with educates-gitops