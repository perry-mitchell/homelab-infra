resource "kubernetes_config_map" "static_files" {
  count = length(var.files) > 0 ? 1 : 0

  metadata {
    name      = "${var.name}-static-files"
    namespace = var.namespace
  }

  data = {
    for file_path, content in var.files : replace(file_path, "/", "_") => content
  }
}
