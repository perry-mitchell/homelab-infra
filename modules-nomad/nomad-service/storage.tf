data "nomad_plugin" "container_storage" {
    count = var.storage != null ? 1 : 0

    plugin_id        = "nfs-${var.storage.name}"
    wait_for_healthy = true
}

locals {
    volumes = var.storage != null ? var.volumes : []
}

module "remote_path" {
    source = "../remote-path"

    for_each = { for _, volume in local.volumes : volume.mount_name => volume }

    ensure_directory = "${var.storage.mount}/${var.name}_${each.value.mount_name}"
    server_chown = var.storage.server_chown
    server_ip = var.storage.server
    server_password = var.storage.server_password
    server_user = var.storage.server_user
}

resource "nomad_csi_volume_registration" "container_storage" {
    for_each = { for _, volume in local.volumes : volume.mount_name => volume }
    depends_on = [ data.nomad_plugin.container_storage, module.remote_path ]

    plugin_id   = data.nomad_plugin.container_storage.0.id
    volume_id   = "service_${var.name}_${each.value.mount_name}"
    name        = "service_${var.name}_${each.value.mount_name}"
    external_id = "service_${var.name}_${each.value.mount_name}"

    capability {
        access_mode     = "multi-node-multi-writer"
        attachment_mode = "file-system"
    }

    mount_options {
        fs_type = "nfs"
        mount_flags = [ "timeo=30", "intr", "vers=3", "_netdev" , "nolock" ]
    }

    context = {
        server = var.storage.server
        share = var.storage.mount
        subDir = "${var.name}_${each.value.mount_name}"
        mountPermissions = "0"
        onDelete = "retain"
    }
}
