module "app_gitsave" {
  source = "../../modules/service2"

  depends_on = [module.longhorn]

  container_port = 3000
  dns_config = {
    cluster_fqdn   = var.cluster_fqdn
    host_ip        = local.primary_ingress_ip
    subdomain_name = "gitsave"
  }
  environment = {
    DISABLE_AUTH = "false"
    JWT_SECRET   = var.gitsave_jwt
  }
  image = {
    tag = "latest"
    uri = "timwitzdam/gitsave"
  }
  longhorn_mounts = {
    data = {
      container_path  = "/app/data"
      storage_request = "1Gi"
    }
  }
  name      = "gitsave"
  namespace = kubernetes_namespace.backup.metadata[0].name
  nfs_mounts = {
    backups = {
      create_subdir   = true
      container_path  = "/app/backups"
      nfs_export      = var.nfs_storage.backup.export
      nfs_server      = var.nfs_storage.backup.host
      storage_request = "100Gi"
    }
  }
  replicas     = 1
  service_port = 80
  tailscale = {
    hostname = "gitsave"
    host_ip  = local.primary_ingress_ip
    tailnet  = var.tailscale_tailnet
  }
}
