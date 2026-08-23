resource "kubernetes_namespace_v1" "arc_system" {
  metadata {
    name = "arc-system"
  }
}

resource "kubernetes_namespace_v1" "runners" {
  metadata {
    name = var.runner_namespace
  }
}

# Referenced by the scale set via `githubConfigSecret` (pre-defined secret variation)
resource "kubernetes_secret" "github_pat" {
  metadata {
    name      = "arc-github-pat"
    namespace = kubernetes_namespace_v1.runners.metadata[0].name
  }

  data = {
    github_token = var.github_pat
  }
}

resource "helm_release" "controller" {
  name       = "gha-runner-scale-set-controller"
  namespace  = kubernetes_namespace_v1.arc_system.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.controller_chart_version
  wait       = true
}

resource "helm_release" "scale_set" {
  name       = "infersec-e2e"
  namespace  = kubernetes_namespace_v1.runners.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.scale_set_chart_version
  wait       = true

  values = [
    yamlencode({
      githubConfigUrl    = "https://github.com/${var.repository}"
      githubConfigSecret = kubernetes_secret.github_pat.metadata[0].name

      scaleSetLabels = var.runner_labels
      minRunners     = var.min_runners
      maxRunners     = var.max_runners

      containerMode = {
        type = "dind"
      }

      controllerServiceAccount = {
        namespace = kubernetes_namespace_v1.arc_system.metadata[0].name
        name      = helm_release.controller.name
      }

      template = {
        spec = {
          containers = [
            {
              name    = "runner"
              image   = "${var.runner_image.uri}:${var.runner_image.tag}"
              command = ["/home/runner/run.sh"]
              resources = {
                requests = {
                  cpu    = var.runner_cpu_request
                  memory = var.runner_memory_request
                }
              }
            }
          ]
        }
      }
    })
  ]

  depends_on = [
    helm_release.controller,
    kubernetes_secret.github_pat,
  ]
}
