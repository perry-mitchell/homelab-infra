locals {
  index_host = var.public_domains[0]
  index_url  = "https://${local.index_host}"
}

module "app_demo" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    demo = {
      image = {
        uri = "nginx"
        tag = "latest"
      }
      ports = [
        {
          container     = 80
          service       = 80
          public_access = {
            hostname = local.index_host
          }
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "index"
  namespace              = kubernetes_namespace.family.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
