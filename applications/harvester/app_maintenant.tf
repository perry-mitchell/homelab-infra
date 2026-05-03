resource "kubernetes_service_account" "maintenant" {
  metadata {
    name      = "maintenant"
    namespace = kubernetes_namespace.monitoring.metadata.0.name
  }
}

resource "kubernetes_cluster_role" "maintenant" {
  metadata {
    name = "maintenant"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "namespaces", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "daemonsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "maintenant" {
  metadata {
    name = "maintenant"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.maintenant.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.maintenant.metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata.0.name
  }
}

module "app_maintenant" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    maintenant = {
      fs_group = 65534
      environment = {
        MAINTENANT_ADDR = "0.0.0.0:8080"
        MAINTENANT_DB = "/data/maintenant.db"
        MAINTENANT_RUNTIME = "kubernetes"
      }
      image = local.images.maintenant
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "50Gi"
        }
      }
      ports = [
        {
          container          = 8080
          service            = 80
          tailscale_hostname = "maintenant"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "maintenant"
  namespace              = kubernetes_namespace.monitoring.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
  service_account_name   = kubernetes_service_account.maintenant.metadata[0].name
}
