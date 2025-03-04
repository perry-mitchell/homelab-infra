module "app_code_server" {
    source = "../../modules/service2"

    depends_on = [ module.longhorn ]

    container_port = 8443
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "code"
    }
    environment = {
        DEFAULT_WORKSPACE = "/config/workspace"
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
        tag = "4.96.4-ls254"
        uri = "lscr.io/linuxserver/code-server"
    }
    longhorn_mounts = {
        config = {
            container_path = "/config"
            storage_request = "50Gi"
        }
    }
    name = "code"
    namespace = kubernetes_namespace.dev.metadata[0].name
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
