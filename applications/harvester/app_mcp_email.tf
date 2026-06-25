locals {
  mcp_email_imap_hosts = {
    outlook  = ""
    fastmail = "imap.fastmail.com"
    custom   = ""
  }
  mcp_email_entries = [
    for a in var.mcp_email : {
      email = a.email
      pass  = a.app_password
      host  = a.imap_host != "" ? a.imap_host : lookup(local.mcp_email_imap_hosts, a.type, "")
    }
  ]
  mcp_email_credentials = join(",", [
    for e in local.mcp_email_entries :
    e.host == "" ? "${e.email}:${e.pass}" : "${e.email}:${e.pass}:${e.host}"
  ])
}

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
        CREDENTIAL_SECRET = random_password.mcp_email_credential_secret.result
        EMAIL_CREDENTIALS = local.mcp_email_credentials
        HOST              = "0.0.0.0"
        MCP_AUTH_DISABLE  = "1"
        PORT              = "8080"
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
