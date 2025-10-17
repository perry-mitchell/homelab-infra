locals {
  setup_tailscale = var.container_port != null && var.service_port != null && var.tailscale != null
}

module "dns_tailscale" {
  source = "../dns-name"
  count  = local.setup_tailscale ? 1 : 0

  cluster_fqdn   = var.tailscale.tailnet
  host_ip        = var.tailscale.host_ip
  subdomain_name = var.tailscale.hostname
}

resource "kubernetes_service" "tailscale" {
  count = local.setup_tailscale ? 1 : 0

  metadata {
    name      = "${var.name}-tailscale"
    namespace = var.namespace
    annotations = merge(
      {
        # "tailscale.com/expose" = "true"
        # "tailscale.com/hostname" = var.tailscale.hostname
        # "tailscale.com/https" = "true"
      },
      try(var.tailscale.funnel, false) ? {
        "tailscale.com/funnel" = "true"
      } : {}
    )
  }

  spec {
    selector = {
      application = kubernetes_deployment.deployment.spec[0].template[0].metadata[0].labels.application
    }

    port {
      name        = var.service_port == 80 ? "http" : "application"
      port        = var.service_port
      target_port = var.container_port
    }
  }
}

resource "kubernetes_ingress_v1" "tailscale" {
  count = local.setup_tailscale ? 1 : 0

  metadata {
    name        = "${var.name}-tailscale"
    namespace   = var.namespace
    annotations = {}
  }

  spec {
    ingress_class_name = "tailscale"

    tls {
      hosts = [
        module.dns_tailscale[0].dns_name
      ]
      secret_name = "${var.name}-tailscale-tls"
    }

    dynamic "rule" {
      for_each = toset(
        var.tailscale != null ? [
          module.dns_tailscale[0].dns_name
        ] : []
      )

      content {
        host = rule.value

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = kubernetes_service.tailscale[0].metadata[0].name

                port {
                  number = kubernetes_service.tailscale[0].spec[0].port[0].port
                }
              }
            }
          }
        }
      }
    }
  }
}
