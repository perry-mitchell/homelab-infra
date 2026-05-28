resource "harvester_image" "image" {
  count = var.image_url != null ? 1 : 0

  name         = coalesce(var.image_name, var.name)
  namespace    = var.image_namespace
  display_name = coalesce(var.image_name, var.name)
  source_type  = "download"
  url          = var.image_url
}

resource "harvester_cloudinit_secret" "cloudinit" {
  count = var.cloud_init_user_data != null ? 1 : 0

  name      = "${var.name}-cloudinit"
  namespace = var.namespace
  user_data = var.cloud_init_user_data
}

locals {
  image_id = var.image_id != null ? var.image_id : try(harvester_image.image[0].id, null)
}

resource "harvester_virtualmachine" "vm" {
  name                 = var.name
  namespace            = var.namespace
  cpu                  = var.cpu
  memory               = var.memory
  efi                  = var.efi
  restart_after_update = var.restart_after_update
  run_strategy         = var.run_strategy
  tags                 = var.tags

  ssh_keys = length(var.ssh_keys) > 0 ? var.ssh_keys : null

  network_interface {
    name           = "nic-1"
    type           = "bridge"
    wait_for_lease = var.tailscale_hostname != null
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.disk_size
    bus        = var.disk_bus
    boot_order = 1
    image      = local.image_id
    auto_delete = true
  }

  dynamic "cloudinit" {
    for_each = var.cloud_init_user_data != null ? [true] : []
    content {
      user_data_secret_name = harvester_cloudinit_secret.cloudinit[0].name
    }
  }
}

resource "kubernetes_service" "vm" {
  count = var.tailscale_hostname != null ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.k8s_namespace
  }

  spec {
    port {
      name        = "http"
      port        = var.service_port
      target_port = var.target_port
    }
  }
}

resource "kubernetes_endpoints_v1" "vm" {
  count = var.tailscale_hostname != null ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.k8s_namespace
  }

  subset {
    address {
      ip = harvester_virtualmachine.vm.network_interface[0].ip_address
    }
    port {
      name = "http"
      port = var.target_port
    }
  }
}

resource "kubernetes_ingress_v1" "tailscale" {
  count = var.tailscale_hostname != null ? 1 : 0

  metadata {
    name      = var.name
    namespace = var.k8s_namespace
  }

  spec {
    ingress_class_name = "tailscale"

    tls {
      hosts = [
        var.tailscale_hostname
      ]
      secret_name = "${var.name}-tls"
    }

    rule {
      host = var.tailscale_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.vm[0].metadata[0].name

              port {
                number = kubernetes_service.vm[0].spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}
