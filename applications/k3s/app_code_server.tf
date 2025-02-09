module "app_code_server" {
    source = "../../modules/service2"

    depends_on = [ module.nfs_storage_export ]

    container_port = 8443
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "code"
    }
    environment = {
        DEFAULT_WORKSPACE = "/data/workspace"
        DOCKER_MODS = join(
            "|",
            [
                "linuxserver/mods:universal-docker-in-docker",
                "linuxserver/mods:code-server-nodejs",
                "linuxserver/mods:code-server-npmglobal",
                "linuxserver/mods:code-server-terraform"
            ]
        )
        NODEJS_MOD_VERSION = "22"
        PGID = "100"
        PUID = "99"
        SUDO_PASSWORD = var.code_auth.sudo_password
        TZ = "Europe/Helsinki"
    }
    image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/code-server"
    }
    name = "code"
    namespace = kubernetes_namespace.dev.metadata[0].name
    nfs_mounts = {
        config = {
            create_subdir = true
            container_path = "/config"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "5Gi"
        }
        data = {
            create_subdir = true
            container_path = "/data"
            nfs_export = var.nfs_storage.appdata.export
            nfs_server = var.nfs_storage.appdata.host
            storage_request = "50Gi"
        }
    }
    privileged = true
    replicas = 1
    service_port = 80
    tailscale = {
        hostname = "code"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
    tailscale_port_alternatives = {
        code1 = {
            hostname = "code1"
            port = 8000
        }
    }
}
