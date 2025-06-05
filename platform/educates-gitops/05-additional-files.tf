# Install additional files if they are provided

# Install theme if file exists
resource "kubectl_manifest" "theme" {
   count = fileexists(var.gitopsConfig.themeFile) ? 1 : 0
   yaml_body = file(var.gitopsConfig.themeFile)
}