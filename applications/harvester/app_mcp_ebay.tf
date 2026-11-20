module "app_mcp_ebay" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    ebay = {
      environment = {
        EBAY_CLIENT_ID     = var.mcp_ebay.client_id
        EBAY_CLIENT_SECRET = var.mcp_ebay.client_secret
        EBAY_ENVIRONMENT   = "production"
        EBAY_MCP_TOOLS     = "browse"
        MCP_HOST           = "0.0.0.0"
        MCP_PORT           = "3000"
        OAUTH_ENABLED      = "false"
      }
      image = local.images.ebay_mcp
      ports = [
        {
          container         = 3000
          service           = 80
          internal_hostname = "mcp-ebay"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mcp-ebay"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
