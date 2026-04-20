variable "deployment_flavor" {
  type        = string
  description = "The type of deployment: 'single-node', 'k3s-cluster', or 'talos-cluster'"
  validation {
    condition     = contains(["single-node", "k3s-cluster", "talos-cluster"], var.deployment_flavor)
    error_message = "Flavor must be one of: single-node, k3s-cluster, talos-cluster."
  }
}

variable "proxmox_endpoint" { 
  type    = string
  default = "https://192.168.1.28:8006" 
}

variable "proxmox_api_token" {
  type      = string
  sensitive = true # This hides the token in your logs
}

variable "proxmox_nodes" {
  type    = list(string)
  default = ["proxmox-server"]
}

variable "proxmox_node" {
  type    = string
  default = "proxmox-server"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key to connect to Proxmox"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "proxmox_image_datastore" {
  description = "Storage for ISOs and Snippets (ej: local)"
  type = object({
    name   = string
    shared = bool
  })
  default = {
    name   = "local"
    shared = false
  }
}

variable "proxmox_vm_datastore" {
  description = "Storage for VMs Disks (ej: data-vms)"
  type = object({
    name   = string
    shared = bool
  })
  validation {
    # If flavor is NOT single-node, shared MUST be true.
    condition     = var.deployment_flavor == "single-node" || var.proxmox_vm_datastore.shared == true
    error_message = "CRITICAL: For cluster deployments, the VM datastore MUST be shared (NFS/Ceph) to ensure HA and data persistence across nodes."
  }
}

variable "cloud_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "proxmox_image_datastore" { 
  type    = string
  default = "data-vms" 
}

variable "proxmox_network_bridge" { 
  type    = string
  default = "vmbr0" 
}

variable "vm_user" {
  type    = string
  default = "ubuntu" # Standard for the Ubuntu image we are using
}

variable "vm_password" {
  description = "Contraseña para el usuario 'debian' en las VMs"
  type        = string
  sensitive   = true # Prevents it from being displayed in plain text in the terminal/logs 
}

variable "ssh_key_path" {
  description = "Local path to the SSH public key to inject into the VMs"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "portal_domain" {
  type    = string
  default = "educates.lab.inet"
}


variable "kube_nodes" {
  description = "Unified node configuration"
  type = map(object({
    type           = string 
    proxmox_host   = number
    ip_address     = string
    mac_address    = string
    vm_cores       = optional(number, 8)
    vm_memory      = optional(number, 16384)
    vm_disk_size   = optional(number, 50)
    config_patches = optional(list(string), [])
  }))
}

variable "educates_version" {
  type    = string
  default = "latest"
}
