terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.97.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = true
}

provider "helm" {
  kubernetes {
    host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  }
}

provider "kubectl" {
  host                   = talos_cluster_kubeconfig.this.kubernetes_client_configuration.host
  client_certificate     = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate)
  load_config_file       = false
}

# --- Locals ---

locals {
  all_proxmox_nodes = distinct(concat(
    [for n in var.control_nodes : n.proxmox_host],
    [for n in var.worker_nodes : n.proxmox_host],
  ))

  primary_control_node_key = keys(var.control_nodes)[0]
  primary_control_node_ip  = var.control_nodes[local.primary_control_node_key].ip_address

  control_node_ips = [for n in var.control_nodes : n.ip_address]
  worker_node_ips  = [for n in var.worker_nodes : n.ip_address]
  all_node_ips     = concat(local.control_node_ips, local.worker_node_ips)

  all_nodes = merge(var.control_nodes, var.worker_nodes)

  nodes_csv = join("\n", [
    for name, node in local.all_nodes :
    "${node.mac_address},${node.ip_address},${name},${name}.${var.dns_domain}"
  ])

  cilium_cni_control_patch = <<-EOT
    cluster:
      network:
        cni:
          name: none
      proxy:
        disabled: true
    EOT
}

# --- Talos Image ---

resource "proxmox_virtual_environment_download_file" "talos_image" {
  for_each     = { for node in local.all_proxmox_nodes : node => node }
  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore
  node_name    = each.value
  url          = "https://factory.talos.dev/image/${var.talos_schematic_id}/v${var.talos_version}/metal-${var.talos_arch}.qcow2"
  file_name    = "${var.talos_cluster_name}-talos-${var.talos_version}-${var.talos_arch}.img"
  overwrite            = true
  overwrite_unmanaged  = true
}

# --- Control Plane VMs ---

resource "proxmox_virtual_environment_vm" "control" {
  for_each  = var.control_nodes
  name      = each.key
  node_name = each.value.proxmox_host

  agent {
    enabled = true
  }

  cpu {
    cores = var.control_vm_cores
    type  = var.proxmox_vm_cpu_type
  }

  memory {
    dedicated = var.control_vm_memory
    floating  = var.control_vm_memory
  }

  disk {
    datastore_id = var.proxmox_image_datastore
    file_id      = proxmox_virtual_environment_download_file.talos_image[each.value.proxmox_host].id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.control_vm_disk_size
  }

  network_device {
    mac_address = each.value.mac_address
    vlan_id     = var.proxmox_network_vlan_id
    bridge      = var.proxmox_network_bridge
  }

  operating_system {
    type = "l26"
  }
}

# --- Worker VMs ---

resource "proxmox_virtual_environment_vm" "worker" {
  for_each  = var.worker_nodes
  name      = each.key
  node_name = each.value.proxmox_host

  agent {
    enabled = true
  }

  cpu {
    cores = var.worker_vm_cores
    type  = var.proxmox_vm_cpu_type
  }

  memory {
    dedicated = var.worker_vm_memory
    floating  = var.worker_vm_memory
  }

  disk {
    datastore_id = var.proxmox_image_datastore
    file_id      = proxmox_virtual_environment_download_file.talos_image[each.value.proxmox_host].id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.worker_vm_disk_size
  }

  network_device {
    mac_address = each.value.mac_address
    vlan_id     = var.proxmox_network_vlan_id
    bridge      = var.proxmox_network_bridge
  }

  dynamic "disk" {
    for_each = lookup(var.worker_extra_disks, each.key, [])
    content {
      datastore_id = disk.value.datastore_id
      file_format  = disk.value.file_format
      file_id      = disk.value.file_id
      interface    = "virtio${disk.key + 1}"
      iothread     = true
      discard      = "on"
      size         = disk.value.size
    }
  }

  operating_system {
    type = "l26"
  }
}

# --- Talos Machine Secrets ---

resource "talos_machine_secrets" "this" {}

# --- Talos Machine Configuration ---

data "talos_machine_configuration" "control" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.primary_control_node_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.primary_control_node_ip}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

# --- Apply Configuration to Nodes ---

resource "talos_machine_configuration_apply" "control" {
  for_each                    = var.control_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control.machine_configuration
  node                        = each.value.ip_address
  config_patches              = concat(
    var.control_machine_config_patches,
    var.kubernetes_cni == "cilium" ? [local.cilium_cni_control_patch] : []
  )

  depends_on = [proxmox_virtual_environment_vm.control]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each                    = var.worker_nodes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.ip_address
  config_patches              = var.worker_machine_config_patches

  depends_on = [proxmox_virtual_environment_vm.worker]
}

# --- Bootstrap First Control Node ---

resource "talos_machine_bootstrap" "this" {
  node                 = local.primary_control_node_ip
  client_configuration = talos_machine_secrets.this.client_configuration

  depends_on = [talos_machine_configuration_apply.control]
}

# --- Generate Kubeconfig ---

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.primary_control_node_ip

  depends_on = [talos_machine_bootstrap.this]
}

# --- Talos Client Configuration ---

data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.control_node_ips
  nodes                = local.all_node_ips
}

# --- DHCP Static Assignments CSV ---

resource "local_file" "nodes_csv" {
  filename = "${path.module}/nodes.csv"
  content  = "${local.nodes_csv}\n"
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
}

# --- Cilium CNI ---

# talos_cluster_kubeconfig completes as soon as it can fetch the config via the
# Talos API (port 50000), but the Kubernetes API server (port 6443) may not be
# listening yet. Poll until it responds before attempting the Helm install.
resource "null_resource" "wait_for_kubernetes_api" {
  count = var.kubernetes_cni == "cilium" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      until curl -sk https://${local.primary_control_node_ip}:6443/version > /dev/null 2>&1; do
        echo "Waiting for Kubernetes API server..."
        sleep 5
      done
    EOT
  }

  depends_on = [talos_cluster_kubeconfig.this]
}

resource "helm_release" "cilium" {
  count      = var.kubernetes_cni == "cilium" ? 1 : 0
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = var.cilium_version
  namespace  = "kube-system"

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  # Use Talos KubePrism (local API load balancer, enabled by default since Talos 1.6)
  # rather than hardcoding the control plane IP — works correctly in single and HA setups
  set {
    name  = "k8sServiceHost"
    value = "localhost"
  }
  set {
    name  = "k8sServicePort"
    value = "7445"
  }
  set {
    name  = "securityContext.capabilities.ciliumAgent"
    value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
  }
  set {
    name  = "securityContext.capabilities.cleanCiliumState"
    value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
  }
  # Talos mounts cgroupv2 at boot; Cilium must not attempt to remount it
  set {
    name  = "cgroup.autoMount.enabled"
    value = "false"
  }
  set {
    name  = "cgroup.hostRoot"
    value = "/sys/fs/cgroup"
  }

  depends_on = [null_resource.wait_for_kubernetes_api]
}

# --- Wait for Cluster Health ---

data "talos_cluster_health" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  control_plane_nodes  = local.control_node_ips
  worker_nodes         = local.worker_node_ips
  endpoints            = local.control_node_ips

  timeouts = {
    read = "15m"
  }

  depends_on = [talos_machine_bootstrap.this, helm_release.cilium]
}

# --- MetalLB ---

resource "kubectl_manifest" "metallb_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: metallb-system
      labels:
        pod-security.kubernetes.io/enforce: privileged
        pod-security.kubernetes.io/audit: privileged
        pod-security.kubernetes.io/warn: privileged
  YAML

  depends_on = [data.talos_cluster_health.this]
}

resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = var.metallb_version
  namespace        = "metallb-system"
  create_namespace = false
  wait             = true

  depends_on = [kubectl_manifest.metallb_namespace]
}

resource "kubectl_manifest" "metallb_default_pool" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: default-pool
      namespace: metallb-system
    spec:
      addresses:
      - ${var.metallb_address_pool}
  YAML

  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "metallb_ingress_pool" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: ingress-pool
      namespace: metallb-system
    spec:
      addresses:
      - ${var.metallb_ingress_address}/32
      serviceAllocation:
        priority: 10
        namespaces:
        - projectcontour
  YAML

  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "metallb_l2_advertisement" {
  yaml_body = <<-YAML
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: advertise-all
      namespace: metallb-system
  YAML

  depends_on = [helm_release.metallb]
}

# --- Contour ---

resource "kubectl_manifest" "contour_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: projectcontour
      labels:
        pod-security.kubernetes.io/enforce: privileged
        pod-security.kubernetes.io/audit: privileged
        pod-security.kubernetes.io/warn: privileged
  YAML

  depends_on = [helm_release.metallb]
}

resource "helm_release" "contour" {
  name             = "contour"
  repository       = "https://projectcontour.github.io/helm-charts/"
  chart            = "contour"
  version          = var.contour_version
  namespace        = "projectcontour"
  create_namespace = false
  wait             = true

  set {
    name  = "contour.replicaCount"
    value = "1"
  }

  set {
    name  = "envoy.useHostPort.http"
    value = "true"
  }

  set {
    name  = "envoy.useHostPort.https"
    value = "true"
  }

  values = [yamlencode({
    configInline = {
      default-http-versions = ["HTTP/1.1"]
    }
  })]

  depends_on = [kubectl_manifest.contour_namespace]
}

# --- Longhorn ---

resource "kubectl_manifest" "longhorn_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: longhorn-system
      labels:
        pod-security.kubernetes.io/enforce: privileged
        pod-security.kubernetes.io/audit: privileged
        pod-security.kubernetes.io/warn: privileged
  YAML

  depends_on = [helm_release.contour]
}

resource "helm_release" "longhorn" {
  name             = "longhorn"
  repository       = "https://charts.longhorn.io"
  chart            = "longhorn"
  version          = var.longhorn_version
  namespace        = "longhorn-system"
  create_namespace = false
  wait             = true

  set {
    name  = "defaultSettings.defaultDataPath"
    value = "/var/mnt/longhorn"
  }

  depends_on = [kubectl_manifest.longhorn_namespace]
}

# --- kapp-controller ---

data "http" "kapp_controller_release" {
  url = "https://github.com/carvel-dev/kapp-controller/releases/download/${var.kapp_controller_version}/release.yml"
}

data "kubectl_file_documents" "kapp_controller" {
  content = data.http.kapp_controller_release.response_body
}

resource "kubectl_manifest" "kapp_controller" {
  for_each  = data.kubectl_file_documents.kapp_controller.manifests
  yaml_body = each.value

  depends_on = [helm_release.metallb]
}

# --- Educates ---

resource "kubectl_manifest" "educates_installer_namespace" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: educates-installer
  YAML

  depends_on = [kubectl_manifest.kapp_controller]
}

resource "kubectl_manifest" "educates_installer_service_account" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: educates-installer
      namespace: educates-installer
  YAML

  depends_on = [kubectl_manifest.educates_installer_namespace]
}

resource "kubectl_manifest" "educates_installer_cluster_role_binding" {
  yaml_body = <<-YAML
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: educates-installer
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: educates-installer
        namespace: educates-installer
  YAML

  depends_on = [kubectl_manifest.educates_installer_service_account]
}

resource "kubectl_manifest" "educates_config_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "educates-installer"
      namespace = "educates-installer"
    }
    stringData = {
      "config.yaml" = file("${path.module}/educates-config.yaml")
    }
  })

  depends_on = [kubectl_manifest.educates_installer_namespace]
}

resource "kubectl_manifest" "educates_tls_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    type       = "kubernetes.io/tls"
    metadata = {
      name      = "grumpys.work-tls"
      namespace = "educates-installer"
    }
    stringData = {
      "tls.crt" = file("${path.module}/grumpys.work.pem")
      "tls.key" = file("${path.module}/grumpys.work.key")
    }
  })

  depends_on = [kubectl_manifest.educates_installer_namespace]
}

resource "kubectl_manifest" "educates_installer_app" {
  yaml_body = <<-YAML
    apiVersion: kappctrl.k14s.io/v1alpha1
    kind: App
    metadata:
      name: installer.educates.dev
      namespace: educates-installer
    spec:
      serviceAccountName: educates-installer
      syncPeriod: 87600h
      fetch:
      - imgpkgBundle:
          image: ghcr.io/educates/educates-installer:${var.educates_version}
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
          - path: bundle/kbld/kbld-images.yaml
          - secretRef:
              name: educates-installer
          - path: values/disable-kapp-controller.yaml
          paths:
          - bundle/kbld/kbld-bundle.yaml
          - bundle/config/kapp
          - bundle/config/ytt
      - kbld:
          paths:
          - bundle/.imgpkg/images.yml
          - '-'
      deploy:
      - kapp:
          rawOptions:
          - --app-changes-max-to-keep=0
  YAML

  depends_on = [
    kubectl_manifest.educates_installer_cluster_role_binding,
    kubectl_manifest.educates_config_secret,
    kubectl_manifest.educates_tls_secret,
  ]
}

resource "null_resource" "educates_installer_app_wait" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for App installer.educates.dev to reconcile..."
      kubectl wait app.kappctrl.k14s.io/installer.educates.dev -n educates-installer \
        --kubeconfig ${path.module}/kubeconfig.yaml \
        --for=condition=ReconcileSucceeded --timeout=600s
    EOT
  }

  depends_on = [
    kubectl_manifest.educates_installer_app,
    local_file.kubeconfig,
  ]
}

resource "terraform_data" "educates_installer_app_deleted" {
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Deleting App installer.educates.dev and waiting for kapp-controller to finish cleanup..."
      kubectl delete app.kappctrl.k14s.io installer.educates.dev -n educates-installer --kubeconfig ${path.module}/kubeconfig.yaml --cascade=foreground --wait=true --timeout=600s 2>/dev/null || true
      SECONDS=0
      while kubectl get app.kappctrl.k14s.io installer.educates.dev -n educates-installer --kubeconfig ${path.module}/kubeconfig.yaml >/dev/null 2>&1; do
        if [ $SECONDS -ge 600 ]; then
          echo "Timed out waiting for App installer.educates.dev to be deleted"
          exit 1
        fi
        echo "Waiting for App installer.educates.dev to be fully removed..."
        sleep 5
      done
      echo "App installer.educates.dev fully deleted."
    EOT
  }

  depends_on = [null_resource.educates_installer_app_wait]
}

output "talos_config" {
  description = "Talos client configuration for use with talosctl"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for use with kubectl"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

# --- Proxmox ---

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://pve01.dmz.grumpys.house:8006/"
}

variable "proxmox_iso_datastore" {
  description = "Proxmox datastore for the Talos qcow2 image"
  type        = string
  default     = "local"
}

variable "proxmox_image_datastore" {
  description = "Proxmox datastore for VM disk images"
  type        = string
  default     = "local-zfs"
}

variable "proxmox_network_bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr0"
}

variable "proxmox_network_vlan_id" {
  description = "Proxmox network VLAN ID"
  type        = number
  default     = 30
}

variable "proxmox_vm_cpu_type" {
  description = "Proxmox emulated CPU type"
  type        = string
  default     = "x86-64-v2-AES"
}

# --- Talos / Cluster ---

variable "talos_cluster_name" {
  description = "Name of the Talos/Kubernetes cluster"
  type        = string
  default     = "educates"
}

variable "talos_version" {
  description = "Version of Talos Linux to use"
  type        = string
  default     = "1.12.6"
}

variable "talos_schematic_id" {
  description = "Talos factory schematic ID (includes qemu-guest-agent, iscsi-tools, util-linux-tools)"
  type        = string
  default     = "53513e54bb39202f35694412577a6bc53d484744d35a126e5d42ef34785c0d83"
}

variable "talos_arch" {
  description = "CPU architecture for Talos image"
  type        = string
  default     = "amd64"
}

variable "dns_domain" {
  description = "DNS domain suffix for node hostnames"
  type        = string
  default     = "dmz.grumpys.house"
}

# --- Node Definitions ---

variable "control_nodes" {
  description = "Map of control node names to their configuration"
  type = map(object({
    proxmox_host = string
    mac_address  = string
    ip_address   = string
  }))
  default = {
    "educates-control-1" = {
      proxmox_host = "pve01"
      mac_address  = "02:00:00:00:01:01"
      ip_address   = "192.168.80.100"
    }
    "educates-control-2" = {
      proxmox_host = "pve02"
      mac_address  = "02:00:00:00:01:02"
      ip_address   = "192.168.80.101"
    }
    "educates-control-3" = {
      proxmox_host = "pve03"
      mac_address  = "02:00:00:00:01:03"
      ip_address   = "192.168.80.102"
    }
  }
}

variable "worker_nodes" {
  description = "Map of worker node names to their configuration"
  type = map(object({
    proxmox_host = string
    mac_address  = string
    ip_address   = string
  }))
  default = {
    "educates-worker-1" = {
      proxmox_host = "pve01"
      mac_address  = "02:00:00:00:02:01"
      ip_address   = "192.168.80.110"
    }
    "educates-worker-2" = {
      proxmox_host = "pve02"
      mac_address  = "02:00:00:00:02:02"
      ip_address   = "192.168.80.111"
    }
    "educates-worker-3" = {
     proxmox_host = "pve03"
     mac_address  = "02:00:00:00:02:03"
     ip_address   = "192.168.80.112"
    }
  }
}

# --- VM Sizing ---

variable "control_vm_cores" {
  description = "Number of CPU cores for control plane VMs"
  type        = number
  default     = 4
}

variable "control_vm_memory" {
  description = "Memory in MB for control plane VMs"
  type        = number
  default     = 4096
}

variable "control_vm_disk_size" {
  description = "Disk size in GB for control plane VMs"
  type        = number
  default     = 32
}

variable "worker_vm_cores" {
  description = "Number of CPU cores for worker VMs"
  type        = number
  default     = 8
}

variable "worker_vm_memory" {
  description = "Memory in MB for worker VMs"
  type        = number
  default     = 49152
}

variable "worker_vm_disk_size" {
  description = "Disk size in GB for worker VMs"
  type        = number
  default     = 250
}

variable "worker_extra_disks" {
  description = "Map of worker node names to a list of extra disk configurations"
  type = map(list(object({
    datastore_id = string
    size         = number
    file_format  = optional(string)
    file_id      = optional(string)
  })))
  default = {}
}

# --- Talos Machine Config Patches ---

variable "control_machine_config_patches" {
  description = "List of config patches to apply to control plane nodes"
  type        = list(string)
  default = [
    <<-EOT
    machine:
      install:
        disk: "/dev/vda"
    EOT
  ]
}

variable "worker_machine_config_patches" {
  description = "List of config patches to apply to worker nodes"
  type        = list(string)
  default = [
    <<-EOT
    machine:
      install:
        disk: "/dev/vda"
      kubelet:
        extraMounts:
          - destination: /var/mnt/longhorn
            type: bind
            source: /var/mnt/longhorn
            options:
              - bind
              - rshared
              - rw
    EOT
  ]
}

# --- CNI ---

variable "kubernetes_cni" {
  description = "CNI to use for Kubernetes. 'flannel' uses Talos built-in default. 'cilium' disables Flannel and installs Cilium via Helm."
  type        = string
  default     = "flannel"

  validation {
    condition     = contains(["flannel", "cilium"], var.kubernetes_cni)
    error_message = "kubernetes_cni must be 'flannel' or 'cilium'."
  }
}

variable "cilium_version" {
  description = "Version of Cilium Helm chart to install (used when kubernetes_cni = 'cilium')"
  type        = string
  default     = "1.19.2"
}

# --- MetalLB ---

variable "metallb_version" {
  description = "Version of MetalLB Helm chart to install"
  type        = string
  default     = "0.15.3"
}

variable "metallb_address_pool" {
  description = "MetalLB default IP address pool range"
  type        = string
  default     = "192.168.80.50-192.168.80.89"
}

variable "metallb_ingress_address" {
  description = "MetalLB IP address reserved for Contour envoy ingress"
  type        = string
  default     = "192.168.80.40"
}

# --- Contour ---

variable "contour_version" {
  description = "Version of Contour Helm chart to install"
  type        = string
  default     = "0.3.0"
}

# --- Longhorn ---

variable "longhorn_version" {
  description = "Version of Longhorn Helm chart to install"
  type        = string
  default     = "1.10.2"
}

# --- kapp-controller ---

variable "kapp_controller_version" {
  description = "Version of kapp-controller to install"
  type        = string
  default     = "v0.59.2"
}

# --- Educates ---

variable "educates_version" {
  description = "Version of Educates training platform to install"
  type        = string
  default     = "3.7.1"
}
