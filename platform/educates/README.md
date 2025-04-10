# Terraform module to install Educates (3.x)

Terraform module for Educates 3.x. This needs to be used after creating a GKE or EKS cluster with the
corresponding Terraform modules for Educates, as they provide some pre-requisites like IAM and WorkloadIdentity.

This module will:

- Deploy kapp-controller (upstream definition)
- Create a kubernetes namespace in the cluster for Educates Carvel app (Defined by variable `educates_app.namespace`)
- Create required RBAC for the Educates Carvel App (Service Account, Cluster Role Binding)
- Create the required Educates Configuration (based of provided variables) and save the configuration in a Secret in the aforementioned namespace
- Create the Educates Carvel App properly configured. It will have an overlay so that kapp-controller, if enabled in config, is removed.

## Configure Educates

Either use provided terraform variables and by selecting the `infrastructure_provider` Educates will be configured with it's default opinions, or
you can provide a a variable `educates_config.config_file` with Educates Configuration format that will be merged with the default module configuration 
(overriding those values that overlap), or will replace the complete configuration if `educates_config.config_is_to_be_merged` is `False`.

## Variables

- `infrastructure_provider`: (__REQUIRED__) What is the underlying infrastructure provider. 
  Currently only `aws` or `gcp` are supported.
- `wildcard_domain`: (__REQUIRED__) Wildcard domain to use for services deployed in the cluster. No defaults.
- `educates_config`: Version of Educates. If a file named `educates-app-config.yaml` is present, configuration 
  will be merged with the one in version control
- `educates_app`: This will set the namespace and syncPeriod for the kapp-controller App. 
  This typically will not need to be changed. syncPeriod is 365 days.
- `aws_config`: Specific configuration for AWS Infrastructure provider
- `gcp_config`: Specific configuration for GCP Infrastructure provider

## Outputs

- `educates.is_kapp_controller_installed`: Is kapp controller installed?
- `educates.educates_installer_version`: Version of Educates installed