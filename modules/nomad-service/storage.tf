data "nomad_plugin" "container_storage" {
    count = var.storage != null ? 1 : 0

    plugin_id        = "nfs-${var.storage.name}"
    wait_for_healthy = true
}

resource "nomad_csi_volume" "container_storage" {
    for_each = var.storage != null ? var.volumes : {}

    plugin_id   = data.nomad_plugin.container_storage.0.id
    volume_id   = "service_${var.name}_${each.key}"
    name = "service_${var.name}_${each.key}"

    capacity_min = "10GiB"
    capacity_max = "20GiB"

    capability {
        access_mode     = "multi-node-multi-writer"
        attachment_mode = "file-system"
    }
}
