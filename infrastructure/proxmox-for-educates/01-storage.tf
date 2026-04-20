resource "proxmox_virtual_environment_download_file" "os_image" {
  # Logic: If datastore.shared is true, loop once. If false, loop per node used.
  for_each = var.proxmox_image_datastore.shared ? (
    toset([var.proxmox_nodes[0]]) 
  ) : (
    toset([for n in var.kube_nodes : var.proxmox_nodes[n.proxmox_host]])
  )
  content_type = "iso"
  datastore_id = var.proxmox_image_datastore.name # Use the 'name' property
  node_name    = each.value
  url          = var.cloud_image_url
  file_name    = "ubuntu-24.04-cloud.img"
}

resource "proxmox_virtual_environment_file" "k3s_cloud_config" {
  # Logic: If flavor is Talos, we create 0 snippets.
  # If it's single-node (k3s), we create snippets for the nodes.
  for_each = var.deployment_flavor == "single-node" ? var.kube_nodes : {}
  content_type = "snippets"
  datastore_id = var.proxmox_image_datastore.name
  # Logic: If your storage is shared, we upload via the first node.
  # If it is local, we upload to the specific node where the VM will live.
  node_name = var.proxmox_image_datastore.shared ? (
    var.proxmox_nodes[0]
  ) : (
    var.proxmox_nodes[each.value.proxmox_host]
  )
  source_raw {
    data = templatefile("${path.module}/templates/k3s-init.tftpl", {
      hostname      = each.key
      # This adds 6 spaces to the start of every line in your config_patches list
      extra_configs = join("\n      ", each.value.config_patches)
    })
    # This names the file on the Proxmox storage (e.g., k3s-init-educates-01.yaml)
    file_name = "k3s-init-${each.key}.yaml"
  }
}