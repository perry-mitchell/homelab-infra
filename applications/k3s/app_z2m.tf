module "app_z2m" {
  source = "../../modules/service2"

  depends_on = [module.longhorn]

  container_port = 8080
  dns_config = {
    cluster_fqdn   = var.cluster_fqdn
    host_ip        = local.primary_ingress_ip
    subdomain_name = "z2m"
  }
  environment = {
    TZ = "Europe/Helsinki"
  }
  image = {
    tag = "latest"
    uri = "koenkk/zigbee2mqtt"
  }
  longhorn_mounts = {
    data = {
      container_path  = "/app/data"
      storage_request = "15Gi"
    }
  }
  name         = "z2m"
  namespace    = kubernetes_namespace.smart_home.metadata[0].name
  replicas = 0
  service_port = 80
  tailscale = {
    hostname = "z2m2"
    host_ip  = local.primary_ingress_ip
    tailnet  = var.tailscale_tailnet
  }
}
