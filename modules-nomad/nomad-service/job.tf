resource "nomad_job" "service" {
    depends_on = [
        nomad_csi_volume_registration.container_storage
    ]

    jobspec = templatefile("${path.module}/job.nomad", {
        cpu = var.resources.cpu
        datacenter = var.datacenter
        docker_cap_add = var.docker_cap_add
        docker_hostname = var.docker_hostname
        docker_network_mode = var.docker_network_mode
        docker_privileged = var.docker_privileged
        docker_volumes = var.docker_volumes
        environment = var.environment
        image = var.image
        memory = var.resources.memory
        mounts = var.mounts
        name = var.name
        ports = var.ports
        volumes = var.volumes
    })
}
