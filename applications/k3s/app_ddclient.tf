module "app_ddclient" {
  source = "../../modules/service2"

  depends_on = [module.longhorn]
  environment = {
    PGID = "100"
    PUID = "99"
    TZ   = "Europe/Helsinki"
  }
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
  name      = "ddclient"
  namespace = kubernetes_namespace.remote_access.metadata[0].name
  replicas  = 0
}
