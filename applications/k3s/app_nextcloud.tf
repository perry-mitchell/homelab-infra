locals {
    nextcloud_k8s_host = join(".", [
        "nextcloud-local",
        kubernetes_namespace.family.metadata[0].name,
        "svc.cluster.local"
    ])
}

resource "random_password" "nextcloud_database_user" {
    length = 32
    special = false
}

module "db_init_nextcloud" {
    source = "../../modules/mysql-init"

    depends_on = [ module.db_mariadb ]

    create_database = "nextcloud"
    create_user = {
        password = random_password.nextcloud_database_user.result
        username = "nextcloud"
    }
    db_host = local.mariadb_service_hostname
    db_password = var.db_mariadb_root
    db_username = "root"
    grant_users = {
        "nextcloud" = "nextcloud"
    }
    name = "nextcloud"
}

resource "kubernetes_storage_class" "nextcloud_storage_nfs" {
    metadata {
        name = "nfs-nextcloud-appdata-data"
    }

    storage_provisioner = "nfs.csi.k8s.io"
    reclaim_policy = "Retain"
    volume_binding_mode = "Immediate"
    allow_volume_expansion = true

    parameters = {
        server = var.nfs_storage.appdata.host
        share =var.nfs_storage.appdata.export
        subDir = "nfsmanual-${kubernetes_namespace.family.metadata[0].name}-nextcloud-data"
    }
}

module "nextcloud_dns" {
    source = "../../modules/dns-name"

    cluster_fqdn = var.cluster_fqdn
    host_ip = local.primary_ingress_ip
    subdomain_name = "nextcloud"
}

module "nextcloud_dns_tailscale" {
    source = "../../modules/dns-name"

    cluster_fqdn = var.tailscale_tailnet
    host_ip = local.primary_ingress_ip
    subdomain_name = "nextcloud"
}

resource "helm_release" "nextcloud" {
    depends_on = [ module.db_init_nextcloud ]

    name       = "nextcloud"
    namespace  = kubernetes_namespace.family.metadata[0].name

    repository = "https://nextcloud.github.io/helm"
    chart      = "nextcloud"
    version    = "6.6.6"
    wait       = true

    set {
        name  = "nextcloud.host"
        value = module.nextcloud_dns_tailscale.dns_name
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
        name  = "nextcloud.trustedDomains"
        value = join(" ", [
            "nextcloud",
            module.nextcloud_dns_tailscale.dns_name,
            module.nextcloud_dns.dns_name,
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
        value = "${local.mariadb_service_hostname}:3306"
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
        value = "longhorn"
    }

    # Persistence

    set {
        name  = "persistence.enabled"
        value = "true"
    }

    set {
        name  = "persistence.storageClass"
        value = "longhorn"
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
}

resource "kubernetes_service" "nextcloud_local" {
    metadata {
        name = "nextcloud-local"
        namespace = kubernetes_namespace.family.metadata[0].name
    }

    spec {
        selector = {
            "app.kubernetes.io/component" = "app"
            "app.kubernetes.io/instance" = "nextcloud"
            "app.kubernetes.io/name" = "nextcloud"
        }

        port {
            name        = "http"
            port        = 80
            target_port = 80
        }
    }
}

resource "kubernetes_service" "nextcloud_tailscale" {
    metadata {
        name = "nextcloud-tailscale"
        namespace = kubernetes_namespace.family.metadata[0].name
        annotations = {
            "tailscale.com/expose" = "true"
            "tailscale.com/hostname" = "nextcloud"
            # "tailscale.com/https" = "true"
        }
    }

    spec {
        selector = {
            "app.kubernetes.io/component" = "app"
            "app.kubernetes.io/instance" = "nextcloud"
            "app.kubernetes.io/name" = "nextcloud"
        }

        port {
            name        = "http"
            port        = 80
            target_port = 80
        }
    }
}

resource "kubernetes_ingress_v1" "nextcloud_local" {
    metadata {
        name = "nextcloud-local"
        namespace = kubernetes_namespace.family.metadata[0].name
        annotations = {
            "nginx.ingress.kubernetes.io/proxy-body-size" = "500m"
        }
    }

    spec {
        ingress_class_name = "nginx"

        dynamic "rule" {
            for_each = toset([
                module.nextcloud_dns.dns_name,
                module.nextcloud_dns_tailscale.dns_name
            ])

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
                        path_type = "Prefix"

                        backend {
                            service {
                                name = kubernetes_service.nextcloud_local.metadata[0].name

                                port {
                                    number = kubernetes_service.nextcloud_local.spec[0].port[0].port
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

resource "kubernetes_ingress_v1" "nextcloud_tailscale" {
    metadata {
        name = "nextcloud-tailscale"
        namespace = kubernetes_namespace.family.metadata[0].name
        annotations = {}
    }

    spec {
        ingress_class_name = "tailscale"

        dynamic "rule" {
            for_each = toset([
                module.nextcloud_dns_tailscale.dns_name
            ])

            content {
                host = rule.value

                http {
                    path {
                        path = "/"
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
