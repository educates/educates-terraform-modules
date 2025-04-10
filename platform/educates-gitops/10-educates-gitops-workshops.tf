#########
## educates ns and rbac
#########
resource "kubectl_manifest" "namespace_gitops_installs" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: "${var.gitopsApp.namespace}"
  YAML

  apply_only = true

  wait_for {
    field {
      key   = "status.phase"
      value = "Active"
    }
  }
}

resource "kubectl_manifest" "serviceaccount_gitops_installs" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: "${var.gitopsApp.namespace}"
      namespace: "${var.gitopsApp.namespace}"
  YAML

  apply_only = true

  depends_on = [
    kubectl_manifest.namespace_gitops_installs
  ]
}

resource "kubectl_manifest" "clusterrolebinding_gitops_installs" {
  yaml_body = <<YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: "${var.gitopsApp.namespace}"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: "${var.gitopsApp.namespace}"
      namespace: "${var.gitopsApp.namespace}"
  YAML

  apply_only = true

  depends_on = [
    # time_sleep.wait_for_kapp_controller,
    kubectl_manifest.serviceaccount_gitops_installs
  ]
}


resource "time_sleep" "k8s_gitops_rbac" {
  create_duration  = "1s" # This time is used to wait for kapp-controller to be available
  destroy_duration = "1s" # This time is used to make sure apps are deleted before the SA

  depends_on = [
    kubectl_manifest.namespace_gitops_installs,
    kubectl_manifest.serviceaccount_gitops_installs,
    kubectl_manifest.clusterrolebinding_gitops_installs
  ]
}

#########
## workshops
#########
locals {
  workshop_gitops_config                         = try(file(var.gitopsApp.configFile), "#comment")
  workshop_gitops_config_indented_encoded_string = indent(15, yamlencode(local.workshop_gitops_config))
}


#TODO: Make gitops username and password optional
# data "kubectl_path_documents" "app_gitops_manifests" {
#   pattern = "${path.module}/manifests/workshop-gitops-app/*.yaml"
#   vars = {
#     k8s_gitops_namespace         = var.k8s_gitops_namespace
#     gitops_environment           = var.gitops_environment
#     gitops_config_syncperiod     = var.gitops_config_syncperiod
#     workshop_gitops_config       = local.workshop_gitops_config_indented_encoded_string
#     gitops_config_subpath_prefix = var.gitops_config_subpath_prefix
#     gitops_config_repo           = var.gitops_config_repo
#     gitops_config_ref            = var.gitops_config_ref
#     gitops_overlays_bundle       = var.gitops_overlays_bundle
#     gitops_github_username       = var.gitops_github_username
#     gitops_github_password       = var.gitops_github_password
#   }
# }

# resource "kubectl_manifest" "app_gitops_manifests_deploy" {
#   for_each  = try(data.kubectl_path_documents.app_gitops_manifests.manifests, toset([]))
#   yaml_body = each.value

#   depends_on = [
#     time_sleep.k8s_gitops_rbac,
#     # kubectl_manifest.educates_app
#   ]
# }

resource "kubectl_manifest" "gitops_credentials" {
  yaml_body = <<YAML
kind: Secret
apiVersion: v1
metadata:
  name: "workshops-gitops-git-creds"
  namespace: "${var.gitopsApp.namespace}"
type: Opaque
stringData:
  username: "${var.gitopsConfig.github.username}"
  password: "${var.gitopsConfig.github.password}"
YAML

  depends_on = [time_sleep.k8s_gitops_rbac]
}

resource "kubectl_manifest" "gitops_app" {
  yaml_body = <<YAML
apiVersion: kappctrl.k14s.io/v1alpha1
kind: App
metadata:
  name: workshop-gitops
  namespace: "${var.gitopsApp.namespace}"
  annotations:
    educates.gitops-workshops.subpath_prefix: "${var.gitopsConfig.subPathPrefix}"
    educates.gitops-workshops.environment: "${var.gitopsConfig.environment}"
spec:
  serviceAccountName: "${var.gitopsApp.namespace}"
  syncPeriod: "${var.gitopsConfig.syncPeriod}"
  fetch:
    - inline:
        paths:
          globals.yaml: ${local.workshop_gitops_config_indented_encoded_string}
      path: environment/globals
    - image:
        secretRef:
          name: workshops-gitops-git-creds
        subPath: gitops-app/src/bundle/config
        url: "${var.gitopsConfig.overlaysBundle}"
      path: config
    - git:
        ref: "${var.gitopsConfig.ref}"
        secretRef:
          name: workshops-gitops-git-creds
        subPath: "${var.gitopsConfig.subPathPrefix}/${var.gitopsConfig.environment}"
        url: "${var.gitopsConfig.configRepo}"
      path: environment/versions
  template:
    - ytt:
        ignoreUnknownComments: true
        paths:
          - config
        valuesFrom:
          - path: "environment/globals"
          - path: "environment/versions/versions.yaml"
          - downwardAPI:
              items:
                - name: config.subPath
                  fieldPath: "metadata.annotations['educates\\.gitops-workshops\\.subpath_prefix']"
          - downwardAPI:
              items:
                - name: environment
                  fieldPath: "metadata.annotations['educates\\.gitops-workshops\\.environment']"
  deploy:
    - kapp:
        rawOptions: ["--app-changes-max-to-keep=5", "--wait-timeout=5m"]
YAML

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
    time_sleep.k8s_gitops_rbac,
    kubectl_manifest.gitops_credentials,
  ]
}
