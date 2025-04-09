output "educates" {
  value = {
    is_kapp_controller_installed = true
    educates_installer_version   = local.educates_installer_oci_image_tag
  }
}