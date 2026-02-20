resource "random_password" "radicale_salt" {
  length           = 8
  special          = true
  override_special = "./"
}

resource "htpasswd_password" "radicale_users" {
  for_each = var.radicale_users

  password = each.value
  salt = random_password.radicale_salt.result
}

locals {
  radicale_htpasswd = join("\n", [
    for user, hash in htpasswd_password.radicale_users :
    "${user}:${hash.apr1}"
  ])
}

module "app_radicale" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    radicale = {
      environment = {
        TZ = "Europe/Helsinki"
      }
      image = local.images.radicale
      longhorn_mounts = {
        var = {
          container_path  = "/radicale/var"
          storage_request = "5Gi"
        }
      }
      ports = [
        {
          container          = 5232
          service            = 80
          # tailscale_hostname = "z2m"
        }
      ]
      static_mounts = {
        "/radicale/etc/default.conf" = file("${path.module}/config/radicale/default.conf")
        "/radicale/etc/users" = local.radicale_htpasswd
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "radicale"
  namespace              = kubernetes_namespace.organisation.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
