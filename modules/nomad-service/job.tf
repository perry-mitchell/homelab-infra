resource "nomad_job" "service" {
    jobspec = templatefile("${path.module}/job.nomad", {
        cpu = var.resources.cpu
        datacenter = var.datacenter
        image = var.image
        memory = var.resources.memory
        name = var.name
        ports = var.ports
        volume_id = var.storage != null ? nomad_csi_volume.container_storage.0.id : null
        volumes = var.volumes
    })
}
