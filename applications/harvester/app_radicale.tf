resource "htpasswd_password" "radicale_users" {
  for_each = var.radicale_users

  password = each.value
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
      image = {
        tag = "3.1.9"
        uri = "11notes/radicale"
      }
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
  replicas               = 1
}
