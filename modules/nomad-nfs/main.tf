resource "nomad_job" "plugin_nfs_controller" {
    jobspec = templatefile("${path.module}/controller.nomad", {
        datacenter = var.datacenter
        nfs_mount = var.mount
        nfs_server = var.server
        plugin_name = var.name
    })
}

resource "nomad_job" "plugin_nfs_nodes" {
    jobspec = templatefile("${path.module}/node.nomad", {
        datacenter = var.datacenter
        nfs_mount = var.mount
        nfs_server = var.server
        plugin_name = var.name
    })
}
