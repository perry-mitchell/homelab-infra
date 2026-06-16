module "app_mcp_caldav" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    caldav = {
      environment = {
        CALDAV_PASS = var.mcp_caldav.pass
        CALDAV_URL  = "http://radicale.organisation.svc.cluster.local"
        CALDAV_USER = var.mcp_caldav.user
      }
      image = local.images.caldav_mcp
      ports = [
        {
          container         = 8123
          service           = 80
          internal_hostname = "mcp-caldav"
        }
      ]
      run_as = {
        group = 1000
        user  = 1000
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mcp-caldav"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
