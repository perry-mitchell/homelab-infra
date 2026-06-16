resource "random_password" "mcp_email_credential_secret" {
  length  = 32
  special = false
}

module "app_mcp_email" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    email = {
      environment = {
        CREDENTIAL_SECRET  = random_password.mcp_email_credential_secret.result
        EMAIL_APP_PASSWORD = var.mcp_email.outlook_app_password
        EMAIL_PROVIDER     = "outlook"
        EMAIL_USER         = var.mcp_email.outlook_user
        HOST               = "0.0.0.0"
        MCP_AUTH_DISABLE   = "1"
        PORT               = "8080"
      }
      fs_group = 1000
      image = local.images.better_email_mcp
      longhorn_mounts = {
        data = {
          container_path  = "/home/node/.better-email-mcp"
          storage_request = "1Gi"
        }
      }
      ports = [
        {
          container         = 8080
          service           = 80
          internal_hostname = "mcp-email"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mcp-email"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
