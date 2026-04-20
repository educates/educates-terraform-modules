locals {
  single_node_ip = [for n in var.kube_nodes : n.ip_address if n.type == "single-node"][0]
}

# --- TLS GENERATION ---
resource "tls_private_key" "educates_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "educates_cert" {
  private_key_pem = tls_private_key.educates_key.private_key_pem
  subject {
    common_name  = "*.${var.portal_domain}"
    organization = "Educates Lab"
  }
  validity_period_hours = 8760
  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}

# --- PROVIDERS ---
provider "kubernetes" {
  host     = "https://${local.single_node_ip}:6443"
  insecure = true
}

provider "kubectl" {
  host     = "https://${local.single_node_ip}:6443"
  insecure = true
}

# --- WAIT LOGIC ---
resource "null_resource" "wait_for_k3s" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.vm_user
      host        = local.single_node_ip
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "until [ -f /etc/rancher/k3s/k3s.yaml ]; do sleep 5; done",
      "echo 'K3s Ready'"
    ]
  }
  depends_on = [proxmox_virtual_environment_vm.kube_node]
}

# --- ENGINE: KAPP-CONTROLLER ---
data "http" "kapp_controller_manifest" {
  url = "https://github.com/carvel-dev/kapp-controller/releases/latest/download/release.yaml"
}

data "kubectl_file_documents" "kapp_controller" {
  content = data.http.kapp_controller_manifest.response_body
}

resource "kubectl_manifest" "kapp_controller" {
  for_each  = data.kubectl_file_documents.kapp_controller.manifests
  yaml_body = each.value
  depends_on = [null_resource.wait_for_k3s]
}

# --- EDUCATES RESOURCES ---
resource "kubectl_manifest" "educates_namespace" {
  yaml_body = "apiVersion: v1\nkind: Namespace\nmetadata:\n  name: educates-installer"
  depends_on = [null_resource.wait_for_k3s]
}

resource "kubernetes_secret" "educates_tls" {
  metadata {
    name      = "educates-der-tls"
    namespace = "educates-installer"
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = tls_self_signed_cert.educates_cert.cert_pem
    "tls.key" = tls_private_key.educates_key.private_key_pem
  }
  depends_on = [kubectl_manifest.educates_namespace]
}

resource "kubernetes_secret" "educates_config" {
  metadata {
    name      = "educates-config"
    namespace = "educates-installer"
  }
  data = {
    "values.yaml" = <<-YAML
      clusterDomain: ${var.portal_domain}
      ingress:
        enabled: true
        className: traefik
      trainingPortal:
        ingress:
          tls:
            secretName: educates-der-tls
    YAML
  }
  depends_on = [kubectl_manifest.educates_namespace]
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
      fetch:
      - imgpkgBundle:
          image: ghcr.io/educates/educates-installer:${var.educates_version}
  YAML
  depends_on = [kubectl_manifest.kapp_controller, kubernetes_secret.educates_config]
}
