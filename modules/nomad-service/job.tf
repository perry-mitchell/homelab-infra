resource "nomad_job" "service" {
    jobspec = templatefile("${path.module}/job.nomad", {
        cpu = var.resources.cpu
        datacenter = var.datacenter
        image = var.image
        memory = var.resources.memory
        name = var.name
        volume_id = nomad_csi_volume.container_storage.id
        volumes = var.volumes
    })
}
