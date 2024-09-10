resource "nomad_job" "plugin_nfs_controller" {
    jobspec = file("${path.module}/controller.nomad")
}

resource "nomad_job" "plugin_nfs_nodes" {
    jobspec = file("${path.module}/node.nomad")
}
