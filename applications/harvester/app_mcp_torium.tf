module "app_mcp_torium" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    torium = {
      command = ["torium-mcp"]
      args = [
        "-t",
        "streamable-http",
        "--host",
        "0.0.0.0",
        "--port",
        "8000"
      ]
      image = local.images.torium_mcp
      longhorn_mounts = {
        data = {
          container_path  = "/root/.config/torium"
          storage_request = "1Gi"
        }
      }
      ports = [
        {
          container         = 8000
          service           = 80
          internal_hostname = "mcp-torium"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mcp-torium"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
