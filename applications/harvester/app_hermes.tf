module "app_hermes" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    hermes = {
      args = ["gateway", "run"]
      environment = {
        HERMES_DASHBOARD                    = "1"
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD = var.hermes.dashboard_password
        HERMES_DASHBOARD_BASIC_AUTH_SECRET   = var.hermes.dashboard_secret
        HERMES_DASHBOARD_BASIC_AUTH_USERNAME = var.hermes.dashboard_username
        HERMES_GATEWAY_BOOTSTRAP_STATE       = "running"
      }
      image = local.images.hermes_agent
      longhorn_mounts = {
        data = {
          container_path  = "/opt/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container          = 9119
          service            = 80
          tailscale_hostname = "hermes"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "hermes"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
