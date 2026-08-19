resource "kubernetes_service_account" "mcp_kubernetes" {
  metadata {
    name      = "mcp-kubernetes"
    namespace = kubernetes_namespace.agents.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "mcp_kubernetes_read_only" {
  metadata {
    name = "mcp-kubernetes-read-only"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "namespaces", "nodes", "events", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "mcp_kubernetes_read_only" {
  metadata {
    name = "mcp-kubernetes-read-only"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.mcp_kubernetes_read_only.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.mcp_kubernetes.metadata[0].name
    namespace = kubernetes_namespace.agents.metadata.0.name
  }
}

module "app_mcp_kubernetes" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    kubernetes = {
      args = [
        "--port",
        "8080",
        "--read-only",
        "--stateless",
        "--toolsets",
        "core"
      ]
      image = local.images.kubernetes_mcp
      ports = [
        {
          container         = 8080
          service           = 80
          internal_hostname = "mcp-kubernetes"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mcp-kubernetes"
  namespace              = kubernetes_namespace.agents.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
  service_account_name   = kubernetes_service_account.mcp_kubernetes.metadata[0].name
}
