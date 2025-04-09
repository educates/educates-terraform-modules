locals{
  install_kapp_controller = true
}

# resource "kubectl_manifest"  "kapp_controller" {
#   for_each = fileset(".", "${path.module}/kapp-controller/*.yaml")
#   yaml_body = file(each.value)

#   # If the filename is in list of files to be created new, then force new
#   #force_new = contains(var.tanzu_reconciler.createnew_filenames_list, each.value) ? true : false
# }
data "kubectl_file_documents" "docs" {
    content = file("${path.module}/kapp-controller/release.yml")
}

resource "kubectl_manifest" "kapp_controller" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}

resource "time_sleep" "wait_for_kapp_controller" {
  # If kapp-controller was removed, we would maybe need to wait some more, or add a destroy time provisioner to wait until all apps are gone
  create_duration = "1s"
  destroy_duration = "1s"

  depends_on = [
    kubectl_manifest.kapp_controller
  ]
}