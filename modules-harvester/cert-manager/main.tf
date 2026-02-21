resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = resource.kubernetes_namespace.cert_manager.metadata[0].name

  repository  = "https://charts.jetstack.io"
  chart       = "cert-manager"
  version     = "1.15.3"
  wait        = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  dynamic "set" {
    for_each = var.ingress_service_ip != null ? [var.ingress_service_ip] : []
    content {
      name  = "hostAliases[0].ip"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.ingress_service_ip != null ? { for idx, hostname in var.public_hostnames : idx => hostname } : {}
    content {
      name  = "hostAliases[0].hostnames[${set.key}]"
      value = set.value
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email = var.letsencrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = var.public_ingress_class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
