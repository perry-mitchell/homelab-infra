data "nomad_plugin" "container_storage" {
    count = var.storage != null ? 1 : 0

    plugin_id        = "nfs-${var.storage.name}"
    wait_for_healthy = true
}

resource "nomad_csi_volume" "container_storage" {
    depends_on  = [data.nomad_plugin.container_storage]
    count = var.storage != null ? 1 : 0

    plugin_id   = data.nomad_plugin.container_storage.0.id
    volume_id   = "container_${var.name}"
    name        = "container_${var.name}"

    capacity_min = "10GiB"
    capacity_max = "20GiB"

    capability {
        access_mode     = "multi-node-multi-writer"
        attachment_mode = "file-system"
    }
}
