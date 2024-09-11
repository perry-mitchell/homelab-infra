data "nomad_plugin" "container_storage" {
    plugin_id        = "nfs-${var.storage.name}"
    wait_for_healthy = true
}

# resource "nomad_volume" "container_storage" {
#     depends_on  = [data.nomad_plugin.container_storage]
#     # type        = "csi"
#     plugin_id   = data.nomad_plugin.container_storage.id
#     volume_id   = "container_${var.name}"
#     name        = "container_${var.name}"
#     external_id = "${var.storage.server}:${var.storage.mount}"

#     capability {
#         access_mode     = "single-node-writer"
#         attachment_mode = "file-system"
#     }
# }

# resource "nomad_csi_volume_registration" "container_storage" {
#     depends_on  = [data.nomad_plugin.container_storage]
#     plugin_id   = data.nomad_plugin.container_storage.id
#     volume_id   = "container_${var.name}"
#     name        = "container_${var.name}"
#     external_id = "${var.storage.server}:${var.storage.mount}"

#     capability {
#     access_mode     = "single-node-writer"
#     attachment_mode = "file-system"
#   }
# }

resource "nomad_csi_volume" "container_storage" {
    depends_on  = [data.nomad_plugin.container_storage]
    plugin_id   = data.nomad_plugin.container_storage.id
    volume_id   = "container_${var.name}"
    name        = "container_${var.name}"
    # external_id = "${var.storage.server}:${var.storage.mount}"

    capacity_min = "10GiB"
    capacity_max = "20GiB"

    capability {
        access_mode     = "multi-node-multi-writer"
        attachment_mode = "file-system"
    }
}
