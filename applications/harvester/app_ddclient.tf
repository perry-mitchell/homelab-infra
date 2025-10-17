module "app_ddclient" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    ddclient = {
      image = {
        tag = "latest"
        uri = "lscr.io/linuxserver/ddclient"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/config"
          storage_request = "100Mi"
        }
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "ddclient"
  namespace              = kubernetes_namespace.dns.metadata.0.name
}
