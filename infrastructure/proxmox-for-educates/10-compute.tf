resource "proxmox_virtual_environment_vm" "kube_node" {
  # We use the flavor variable to control which nodes are created
  for_each = var.kube_nodes 

  name      = each.key
  node_name = var.proxmox_nodes[each.value.proxmox_host]
  agent { enabled = true }

  cpu {
    cores = each.value.vm_cores
    # Using 'host' allows nested virtualization/better performance 
    # but requires identical CPUs in the cluster.
    type  = "x86-64-v2-AES" 
  }

  memory { dedicated = each.value.vm_memory }

  disk {
    datastore_id = var.proxmox_vm_datastore.name
    
    file_id = var.proxmox_image_datastore.shared ? (
      proxmox_virtual_environment_download_file.os_image[var.proxmox_nodes[0]].id
    ) : (
      proxmox_virtual_environment_download_file.os_image[var.proxmox_nodes[each.value.proxmox_host]].id
    )

    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = each.value.vm_disk_size
  }

  network_device {
    mac_address = lookup(each.value, "mac_address", null)
    bridge      = var.proxmox_network_bridge
  }

  initialization {
    datastore_id = var.proxmox_image_datastore.name

    # MODIFICATION: Only use the snippet if the flavor is single-node/k3s
    user_data_file_id = var.deployment_flavor == "single-node" ? (
      proxmox_virtual_environment_file.k3s_cloud_config[each.key].id
    ) : null

    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = "192.168.80.1" 
      }
    }

    user_account {
      username = var.vm_user
      keys     = [trimspace(file(var.ssh_key_path))]
    }
  }
}