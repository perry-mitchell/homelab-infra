# locals {
#     static_mounts_raw = toset(flatten([
#         for container_name, container in var.containers : [
#             for storage_name, config in container.static_files : {
#                 "${container_name}-${storage_name}" = {
#                     container_name = container_name
#                     container_path = config.container_path
#                     storage_name = storage_name
#                     storage_request = config.storage_request
#                 }
#             }
#         ]
#     ]))
#     static_mounts = merge(local.static_mounts_raw...)
# }

# resource "kubernetes_config_map" "static_files" {
#     count = length(static_mounts) > 0 ? 1 : 0

#     metadata {
#         name = "${var.name}-static-files"
#         namespace = var.namespace
#     }

#     data = {
#         for file_path, content in static_mounts : replace(file_path, "/", "_") => content
#     }
# }

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
