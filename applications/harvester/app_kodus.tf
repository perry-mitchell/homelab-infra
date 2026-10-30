# Kodus - self-hosted AI code review (Kody)
#
# Deployed via the official Helm chart (chart 0.2.10 pins app 2.2.6). The chart
# runs web/api/worker/webhooks plus bundled pgvector Postgres, MongoDB and
# RabbitMQ StatefulSets in this namespace.
#
# Exposure: a single public hostname (kodus.<public_domain>). The web UI proxies
# API traffic server-side (WEB_HOSTNAME_API stays in-cluster by chart default),
# and GitHub webhooks are routed by exact path to the dedicated webhooks service,
# which serves /github/webhook at its root. The chart's own ingress is disabled
# because it only supports one service per host.
#
# LLM providers are managed in the Kodus UI (AI providers / BYOK), not via env
# Fixed Mode - see the locals below for the URLs used when adding them there.

locals {
  kodus_host        = "kodus.${var.public_domain}"
  kodus_url         = "https://${local.kodus_host}"
  kodus_webhook_url = "${local.kodus_url}/github/webhook"
}

resource "helm_release" "kodus" {
  name      = "kodus"
  namespace = kubernetes_namespace.programming.metadata[0].name

  repository = "oci://ghcr.io/kodustech/charts"
  chart      = "kodus"
  version    = "0.2.10"
  wait       = true

  # Lift the chart's hardcoded 100Mi /tmp emptyDir cap (see the script) so
  # review agents are not evicted mid-review
  postrender {
    binary_path = "${path.module}/scripts/kodus-postrender.sh"
  }

  values = [yamlencode({
    global = {
      labels = {
        "kodus.io/environment" = "production"
        "kodus.io/team"        = "perry"
      }

      config = {
        NEXTAUTH_URL                       = local.kodus_url
        API_GITHUB_CODE_MANAGEMENT_WEBHOOK = local.kodus_webhook_url

        # GitHub App (code review integration + install flow)
        API_GITHUB_APP_ID        = var.kodus_github_app.app_id
        GLOBAL_GITHUB_CLIENT_ID  = var.kodus_github_app.client_id
        WEB_GITHUB_INSTALL_URL   = var.kodus_github_app.install_url

        # mcp-manager is disabled below
        API_MCP_SERVER_ENABLED = "false"
      }
    }

    # Homelab sizing: single replica per service, no HPA (replicas are honored
    # directly when autoscaling is off)
    autoscaling = {
      enabled = false
    }

    services = {
      web = {
        replicas = local.deployments_enabled.service ? 1 : 0

        # GitHub OAuth app for "Sign in with GitHub" - not part of the chart's
        # fixed secret-key list, so it rides the generic per-service env block
        env = {
          WEB_OAUTH_GITHUB_CLIENT_ID = var.kodus_github_oauth.client_id
        }
      }
      api      = { replicas = local.deployments_enabled.service ? 1 : 0 }
      worker   = { replicas = local.deployments_enabled.service ? 1 : 0 }
      webhooks = { replicas = local.deployments_enabled.service ? 1 : 0 }

      # Optional services trimmed for a lean code-review-only install
      "mcp-manager"      = { enabled = false }
      "worker-analytics" = { enabled = false }
    }

    # Replaced by kubernetes_ingress_v1.kodus (single host, path-routed)
    ingress = {
      enabled = false
    }

    networkPolicy = {
      ingressControllerLabels = {
        "app.kubernetes.io/name" = "ingress-nginx"
      }
      ingressControllerNamespaceSelector = {
        matchLabels = { "kubernetes.io/metadata.name" = "public-ingress" }
      }
    }

    postgres = {
      bundled = { storage = { storageClass = var.longhorn_storage_class } }
    }
    mongodb = {
      bundled = { storage = { storageClass = var.longhorn_storage_class } }
    }
    rabbitmq = {
      bundled = { storage = { storageClass = var.longhorn_storage_class } }
    }
  })]

  set_sensitive {
    name  = "services.web.env.WEB_OAUTH_GITHUB_CLIENT_SECRET"
    value = var.kodus_github_oauth.client_secret
  }

  set_sensitive {
    name  = "global.secrets.API_GITHUB_CLIENT_SECRET"
    value = var.kodus_github_app.client_secret
  }

  set_sensitive {
    name  = "global.secrets.API_GITHUB_PRIVATE_KEY"
    value = var.kodus_github_app.private_key
  }
}

resource "kubernetes_ingress_v1" "kodus" {
  metadata {
    name      = "kodus"
    namespace = kubernetes_namespace.programming.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "nginx-public"

    tls {
      hosts       = [local.kodus_host]
      secret_name = "kodus-tls"
    }

    rule {
      host = local.kodus_host

      http {
        path {
          path      = "/github/webhook"
          path_type = "Exact"

          backend {
            service {
              # Chart-rendered service names are "<release>-<service>"
              name = "kodus-webhooks"

              port {
                number = 3332
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kodus-web"

              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kodus]
}
