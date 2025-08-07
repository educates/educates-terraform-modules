#########
## educates ns and rbac
#########
resource "kubectl_manifest" "namespace_app_installs" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: "${var.educates_app.namespace}"
  YAML

  apply_only = true

  wait_for {
    field {
      key   = "status.phase"
      value = "Active"
    }
  }

  depends_on = [
    kubectl_manifest.kapp_controller,
    time_sleep.wait_for_kapp_controller
  ]
}

resource "kubectl_manifest" "serviceaccount_app_installs" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: "${var.educates_app.namespace}"
      namespace: "${var.educates_app.namespace}"
  YAML

  apply_only = true

  depends_on = [
    kubectl_manifest.namespace_app_installs
  ]
}

resource "kubectl_manifest" "clusterrolebinding_app_installs" {
  yaml_body = <<YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: "${var.educates_app.namespace}"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: "${var.educates_app.namespace}"
      namespace: "${var.educates_app.namespace}"
  YAML

  apply_only = true

  depends_on = [
    kubectl_manifest.serviceaccount_app_installs
  ]
}


resource "time_sleep" "k8s_app_rbac" {
  create_duration  = "1s" # This time is used to wait for kapp-controller to be available
  destroy_duration = "1s" # This time is used to make sure apps are deleted before the SA

  depends_on = [
    kubectl_manifest.namespace_app_installs,
    kubectl_manifest.serviceaccount_app_installs,
    kubectl_manifest.clusterrolebinding_app_installs
  ]
}

#########
## educates app
#########
locals {
  default_educates_config_generic = {
    clusterSecurity = {
      policyEngine = "kyverno"
    }
    clusterIngress = {
      domain = "${var.wildcard_domain}"
    }
    lookupService = {
      enabled = true
    }
  }
  default_educates_config_aws = {
    clusterInfrastructure = {
      provider = "eks"
      aws = {
        region = "${var.aws_config.region}"
        irsaRoles = {
          external-dns = "arn:aws:iam::${var.aws_config.account_id}:role/svc.bot.route53.external-dns-${var.aws_config.cluster_name}"
          cert-manager = "arn:aws:iam::${var.aws_config.account_id}:role/svc.bot.route53.cert-manager-${var.aws_config.cluster_name}"
        }
        route53 = {
          hostedZone = "${var.aws_config.dns_zone}"
        }
      }
    }
  }
  default_educates_config_gcp = {
    clusterInfrastructure = {
      provider = "gke"
      gcp = {
        project = "${var.gcp_config.project}"
        cloudDNS = {
          zone = "${var.gcp_config.dns_zone}"
        }
        workloadIdentity = {
          external-dns = var.gcp_config.externaldns_service_account != "" ? var.gcp_config.externaldns_service_account : "${var.gcp_config.cluster_name}-ext-dns@${var.gcp_config.project}.iam.gserviceaccount.com"
          cert-manager = var.gcp_config.certmanager_service_account != "" ? var.gcp_config.certmanager_service_account : "${var.gcp_config.cluster_name}-cert-mgr@${var.gcp_config.project}.iam.gserviceaccount.com"
        }
      }
    }
  }

  educates_installer_oci_image     = lookup(var.educates_config, "installer_oci_image")
  educates_installer_version       = lookup(var.educates_config, "version")
  educates_installer_oci_image_tag = "${local.educates_installer_oci_image}:${local.educates_installer_version}"
  educates_app_config_file         = lookup(var.educates_config, "config_file")
  educates_config_is_to_be_merged  = lookup(var.educates_config, "config_is_to_be_merged")

  educates_config = try(yamldecode(file(local.educates_app_config_file)), {})
}

module "deepmerge_aws_config" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.6"
  count   = var.infrastructure_provider == "aws" ? 1 : 0
  maps = [
    local.default_educates_config_generic,
    local.default_educates_config_aws
  ]
}

module "deepmerge_gcp_config" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.6"
  count   = var.infrastructure_provider == "gcp" ? 1 : 0
  maps = [
    local.default_educates_config_generic,
    local.default_educates_config_gcp
  ]
}

module "deepmerge_educates_app_config" {
  source  = "Invicton-Labs/deepmerge/null"
  version = "0.1.6"
  maps = [
    try(module.deepmerge_aws_config[0].merged, {}),
    try(module.deepmerge_gcp_config[0].merged, {}),
    local.educates_config
  ]
}

resource "kubectl_manifest" "educates_app_secret" {
  yaml_body = <<YAML
kind: Secret
apiVersion: v1
metadata:
  name: "${var.educates_app.namespace}"
  namespace: "${var.educates_app.namespace}"
type: Opaque
data:
  values.yaml: ${local.educates_config_is_to_be_merged ? base64encode(yamlencode(module.deepmerge_educates_app_config.merged)) : base64encode(yamlencode(local.educates_config))}
YAML

  depends_on = [time_sleep.k8s_app_rbac]
}

resource "kubectl_manifest" "educates_app" {
  yaml_body = <<YAML
apiVersion: "kappctrl.k14s.io/v1alpha1"
kind: App
metadata:
  name: educates
  namespace: "${var.educates_app.namespace}"
spec:
  syncPeriod: "${var.educates_app.sync_period}"
  serviceAccountName: "${var.educates_app.namespace}"
  fetch:
    - imgpkgBundle:
        image: "${local.educates_installer_oci_image_tag}"
      path: bundle
    - inline:
        paths:
          disable-kapp-controller.yaml: |
            clusterPackages:
              kapp-controller:
                enabled: false
      path: values
  template:
    - ytt:
        valuesFrom:
          - path: "bundle/kbld/kbld-images.yaml"
          - secretRef:
              name: "${var.educates_app.namespace}"
          - path: values/disable-kapp-controller.yaml
        paths:
          - "bundle/kbld/kbld-bundle.yaml"
          - "bundle/config/kapp"
          - "bundle/config/ytt"
    - kbld:
        paths:
          - "bundle/.imgpkg/images.yml"
          - "-"
  deploy:
    - kapp:
        rawOptions:
          - "--app-changes-max-to-keep=5"
          - "--diff-changes=false"
          - "--wait-timeout=5m"
YAML
  wait      = true #! This will wait on deletion

  #! This will wait for complete creation
  wait_for {
    field {
      key   = "status.conditions.[0].type"
      value = "ReconcileSucceeded"
    }
    field {
      key   = "status.conditions.[0].status"
      value = "True"
    }
  }
  depends_on = [
    time_sleep.k8s_app_rbac,
    kubectl_manifest.educates_app_secret,
  ]
}
