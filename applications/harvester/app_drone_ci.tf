locals {
  drone_host = "ci.${var.public_domain}"
}

resource "helm_release" "drone" {
  name      = "drone"
  namespace = kubernetes_namespace.programming.metadata[0].name

  repository = "https://charts.drone.io"
  chart      = "drone"

  set {
    name  = "env.DRONE_SERVER_HOST"
    value = local.drone_host
  }

  set {
    name  = "env.DRONE_SERVER_PROTO"
    value = "https"
  }

  set {
    name  = "env.DRONE_GITHUB_CLIENT_ID"
    value = var.drone_ci.github_client_id
  }

  set_sensitive {
    name  = "env.DRONE_GITHUB_CLIENT_SECRET"
    value = var.drone_ci.github_client_secret
  }

  set_sensitive {
    name  = "env.DRONE_RPC_SECRET"
    value = var.drone_ci.rpc_secret
  }

  set {
    name  = "env.DRONE_USER_CREATE"
    value = replace(var.drone_ci.admin_user, ",", "\\,")
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.className"
    value = "nginx-public"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/ssl-redirect"
    value = "true"
    type  = "string"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = local.drone_host
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = local.drone_host
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "drone-tls"
  }

  set {
    name  = "persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "persistentVolume.storageClass"
    value = var.longhorn_storage_class
  }

  set {
    name  = "replicaCount"
    value = local.deployments_enabled.service ? 1 : 0
  }
}

resource "helm_release" "drone_runner" {
  name      = "drone-runner"
  namespace = kubernetes_namespace.programming.metadata[0].name

  repository = "https://charts.drone.io"
  chart      = "drone-runner-docker"

  set {
    name  = "env.DRONE_RPC_HOST"
    value = "drone:8080"
  }

  set {
    name  = "env.DRONE_RPC_PROTO"
    value = "http"
  }

  set_sensitive {
    name  = "env.DRONE_RPC_SECRET"
    value = var.drone_ci.rpc_secret
  }

  set {
    name  = "dind.securityContext.privileged"
    value = "true"
  }

  set {
    name  = "autoscaling.enabled"
    value = "true"
  }

  set {
    name  = "autoscaling.minReplicas"
    value = "1"
  }

  set {
    name  = "autoscaling.maxReplicas"
    value = "3"
  }

  set {
    name  = "autoscaling.targetCPUUtilizationPercentage"
    value = "80"
  }
}
