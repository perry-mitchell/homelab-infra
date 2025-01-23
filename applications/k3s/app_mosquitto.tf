module "app_mosquitto" {
    source = "../../modules/service"

    depends_on = [ module.nfs_storage_subdir ]

    container_port = 1883
    dns_config = {
        cluster_fqdn = var.cluster_fqdn
        host_ip = local.primary_ingress_ip
        subdomain_name = "mosquitto"
    }
    environment = {
      TZ = "Europe/Helsinki"
    }
    files = {
        "/mosquitto/config/mosquitto.conf" = file("${path.module}/config/mosquitto/mosquitto.conf")
    }
    image = {
        tag = "2"
        uri = "eclipse-mosquitto"
    }
    name = "mosquitto"
    namespace = kubernetes_namespace.smart_home.metadata[0].name
    service_port = 1883
    subdir_mounts = {
        data = {
            container_path = "/mosquitto/data"
            storage = "appdata"
            storage_request = "10Gi"
        }
        logs = {
            container_path = "/mosquitto/log"
            storage = "appdata"
            storage_request = "15Gi"
        }
    }
    tailscale = {
        hostname = "mosquitto"
        host_ip = local.primary_ingress_ip
        tailnet = var.tailscale_tailnet
    }
}
