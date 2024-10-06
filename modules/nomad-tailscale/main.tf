data "nomad_plugin" "container_storage" {
    count = var.storage != null ? 1 : 0

    plugin_id        = "nfs-${var.storage.name}"
    wait_for_healthy = true
}

resource "nomad_csi_volume" "container_storage" {
    plugin_id   = data.nomad_plugin.container_storage.0.id
    volume_id   = "daemon_${var.name}_state"
    name        = "daemon_${var.name}_state"

    capacity_min = "10GiB"
    capacity_max = "20GiB"

    capability {
        access_mode     = "multi-node-multi-writer"
        attachment_mode = "file-system"
    }
}

resource "nomad_job" "service" {
    jobspec = templatefile("${path.module}/job.nomad", {
        cpu = var.resources.cpu
        datacenter = var.datacenter
        memory = var.resources.memory
        name = var.name
        tailscale_auth_key = var.tailscale_auth_key
        tailscale_hostname = var.tailscale_hostname
        tailscale_routes = var.tailscale_routes
    })
}
