locals {
  nextcloud_k8s_host = join(".", [
    "nextcloud-local",
    kubernetes_namespace.family.metadata[0].name,
    "svc.cluster.local"
  ])
  nextcloud_host = "nextcloud.${var.tailscale_tailnet}"
  nextcloud_url = "https://${local.nextcloud_host}"
}

#region DB
module "db_nextcloud_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "nextcloud-mariadb" = {
      environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ                    = "Europe/Helsinki"
      }
      image = {
        tag = "12"
        uri = "mariadb"
      }
      longhorn_mounts = {
        mysql = {
          container_path  = "/var/lib/mysql"
          storage_request = "25Gi"
        }
      }
      ports = [
        {
          container         = 3306
          internal_hostname = "nextcloud-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "nextcloud-mariadb"
  namespace              = kubernetes_namespace.storage.metadata.0.name
  replicas = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "nextcloud_database_user" {
  length  = 32
  special = false
}

module "db_init_nextcloud" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_nextcloud_mariadb]

  create_database = "nextcloud"
  create_user = {
    password = random_password.nextcloud_database_user.result
    username = "nextcloud"
  }
  db_host     = "nextcloud-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "nextcloud" = "nextcloud"
  }
  name      = "nextcloud"
  namespace = kubernetes_namespace.storage.metadata.0.name
}
#endregion

#region Storage
resource "kubernetes_storage_class" "nextcloud_storage_nfs" {
  metadata {
    name = "nfs-nextcloud-appdata-data"
  }

  storage_provisioner    = "nfs.csi.k8s.io"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "Immediate"
  allow_volume_expansion = true

  parameters = {
    server = var.nfs_storage.appdata.host
    share  = var.nfs_storage.appdata.export
    subDir = "nfsmanual-${kubernetes_namespace.storage.metadata[0].name}-nextcloud-data"
  }
}
#endregion

#region Helm
resource "helm_release" "nextcloud" {
  depends_on = [module.db_init_nextcloud]

  name      = "nextcloud"
  namespace = kubernetes_namespace.storage.metadata[0].name

  repository = "https://nextcloud.github.io/helm"
  chart      = "nextcloud"
  version    = "8.5.2"
  wait       = true

  set {
    name  = "nextcloud.host"
    value = local.nextcloud_host
  }

  set {
    name  = "nextcloud.username"
    value = var.nextcloud_auth.username
  }

  set {
    name  = "nextcloud.password"
    value = var.nextcloud_auth.password
  }

  set {
    name = "nextcloud.trustedDomains"
    value = join(" ", [
      "nextcloud",
      local.nextcloud_host,
      local.nextcloud_k8s_host
    ])
  }

  set {
    name  = "nextcloud.datadir"
    value = "/var/www/html/data"
  }

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  # Database

  set {
    name  = "internalDatabase.enabled"
    value = "false"
  }

  set {
    name  = "externalDatabase.enabled"
    value = "true"
  }

  set {
    name  = "externalDatabase.type"
    value = "mysql"
  }

  set {
    name  = "externalDatabase.host"
    value = "nextcloud-mariadb:3306"
  }

  set {
    name  = "externalDatabase.database"
    value = "nextcloud"
  }

  set {
    name  = "externalDatabase.user"
    value = "nextcloud"
  }

  set {
    name  = "externalDatabase.password"
    value = random_password.nextcloud_database_user.result
  }

  set {
    name  = "redis.enabled"
    value = "true"
  }

  set {
    name  = "redis.auth.enabled"
    value = "false"
  }

  set {
    name  = "redis.global.storageClass"
    value = var.longhorn_storage_class
  }

  # Persistence

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.storageClass"
    value = var.longhorn_storage_class
  }

  set {
    name  = "persistence.size"
    value = "30Gi"
  }

  set {
    name  = "persistence.nextcloudData.enabled"
    value = "true"
  }

  set {
    name  = "persistence.nextcloudData.storageClass"
    value = kubernetes_storage_class.nextcloud_storage_nfs.metadata.0.name
  }

  set {
    name  = "persistence.nextcloudData.size"
    value = "500Gi"
  }

  # Proxies

    set {
    name  = "nextcloud.extraEnv[0].name"
    value = "OVERWRITEPROTOCOL"
  }

  set {
    name  = "nextcloud.extraEnv[0].value"
    value = "https"
  }

  set {
    name  = "nextcloud.extraEnv[1].name"
    value = "OVERWRITECLIURL"
  }

  set {
    name  = "nextcloud.extraEnv[1].value"
    value = local.nextcloud_url
  }

  set {
    name  = "nextcloud.extraEnv[2].name"
    value = "TRUSTED_PROXIES"
  }

  set {
    name  = "nextcloud.extraEnv[2].value"
    value = "10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
  }

  # Shutdown

  set {
    name  = "replicaCount"
    value = local.deployments_enabled.service ? 1 : 0
  }

  set {
    name  = "cronjob.enabled"
    value = local.deployments_enabled.service
  }

  set {
    name  = "redis.master.count"
    value = local.deployments_enabled.datasource ? 1 : 0
  }

  set {
    name  = "redis.replica.replicaCount"
    value = local.deployments_enabled.datasource ? 3 : 0
  }
}
#endregion

#region Ingress
resource "kubernetes_service" "nextcloud_tailscale" {
  metadata {
    name      = "nextcloud-tailscale"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/component" = "app"
      "app.kubernetes.io/instance"  = "nextcloud"
      "app.kubernetes.io/name"      = "nextcloud"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "nextcloud_tailscale" {
  metadata {
    name        = "nextcloud-tailscale"
    namespace   = kubernetes_namespace.storage.metadata[0].name
    annotations = {}
  }

  spec {
    ingress_class_name = "tailscale"

    tls {
      hosts = [
        local.nextcloud_host
      ]
      secret_name = "nextcloud-tls"
    }

    dynamic "rule" {
      for_each = toset([
        local.nextcloud_host
      ])

      content {
        host = rule.value

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = kubernetes_service.nextcloud_tailscale.metadata[0].name

                port {
                  number = kubernetes_service.nextcloud_tailscale.spec[0].port[0].port
                }
              }
            }
          }
        }
      }
    }
  }
}
#endregion
