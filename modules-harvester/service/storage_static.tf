resource "kubernetes_config_map" "static_files" {
  for_each = {
    for container_name, container in var.containers :
    container_name => container
    if length(container.static_mounts) > 0
  }

  metadata {
    name      = "${var.name}-${each.key}-static-files"
    namespace = var.namespace
  }

  data = {
    for file_path, content in each.value.static_mounts :
    replace(file_path, "/", "_") => content
  }
}
