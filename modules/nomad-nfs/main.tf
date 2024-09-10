resource "nomad_job" "plugin_nfs_controller" {
    jobspec = templatefile("${path.module}/controller.nomad", {
        datacenter = var.datacenter
        nfs_mount = var.storage.mount
        nfs_server = var.storage.server
        plugin_name = var.storage.name
    })
}

resource "nomad_job" "plugin_nfs_nodes" {
    jobspec = templatefile("${path.module}/node.nomad", {
        datacenter = var.datacenter
        nfs_mount = var.storage.mount
        nfs_server = var.storage.server
        plugin_name = var.storage.name
    })
}
