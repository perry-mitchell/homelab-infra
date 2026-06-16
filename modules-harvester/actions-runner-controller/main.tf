resource "kubernetes_namespace_v1" "arc_system" {
  metadata {
    name = "arc-system"
  }
}

resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = var.runner_namespace
  }
}

resource "kubernetes_secret" "github_pat" {
  metadata {
    name      = "arc-github-pat"
    namespace = resource.kubernetes_namespace_v1.arc_system.metadata[0].name
  }

  data = {
    github_token = var.github_pat
  }
}

resource "helm_release" "arc" {
  name       = "actions-runner-controller"
  namespace  = resource.kubernetes_namespace_v1.arc_system.metadata[0].name
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  version    = "0.23.3"
  wait       = true

  set {
    name  = "authSecret.create"
    value = "false"
  }

  set {
    name  = "authSecret.name"
    value = kubernetes_secret.github_pat.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "npm_cache" {
  metadata {
    name      = "runner-npm-cache"
    namespace = var.runner_namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.npm_cache_storage
      }
    }
    storage_class_name = var.longhorn_storage_class
  }

  depends_on = [resource.kubernetes_namespace_v1.arc_runners]
}

resource "kubernetes_persistent_volume_claim" "general_cache" {
  metadata {
    name      = "runner-general-cache"
    namespace = var.runner_namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.general_cache_storage
      }
    }
    storage_class_name = var.longhorn_storage_class
  }

  depends_on = [resource.kubernetes_namespace_v1.arc_runners]
}

resource "kubectl_manifest" "runner_deployment" {
  yaml_body = yamlencode({
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "e2e-runner"
      namespace = var.runner_namespace
    }
    spec = {
      replicas = var.runner_replicas
      template = {
        spec = {
          repository     = var.repository
          image          = "${var.runner_image.uri}:${var.runner_image.tag}"
          labels         = var.runner_labels
          ephemeral      = true
          dockerEnabled  = true

          resources = {
            requests = {
              cpu    = var.runner_cpu_request
              memory = var.runner_memory_request
            }
          }

          volumeMounts = [
            {
              name      = "npm-cache"
              mountPath = "/home/runner/.npm"
            },
            {
              name      = "general-cache"
              mountPath = "/home/runner/.cache"
            }
          ]

          volumes = [
            {
              name = "npm-cache"
              persistentVolumeClaim = {
                claimName = kubernetes_persistent_volume_claim.npm_cache.metadata[0].name
              }
            },
            {
              name = "general-cache"
              persistentVolumeClaim = {
                claimName = kubernetes_persistent_volume_claim.general_cache.metadata[0].name
              }
            }
          ]
        }
      }
    }
  })

  depends_on = [helm_release.arc]
}
