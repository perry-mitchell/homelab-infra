resource "kubernetes_namespace" "authentication" {
  metadata {
    name = "authentication"
  }
}

resource "kubernetes_namespace" "backup" {
  metadata {
    name = "backup"
  }
}

resource "kubernetes_namespace" "collecting" {
  metadata {
    name = "collecting"
  }
}

resource "kubernetes_namespace" "dns" {
  metadata {
    name = "dns"
  }
}

resource "kubernetes_namespace" "entertainment" {
  metadata {
    name = "entertainment"
  }
}

resource "kubernetes_namespace" "family" {
  metadata {
    name = "family"
  }
}

resource "kubernetes_namespace" "freelancing" {
  metadata {
    name = "freelancing"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "smart_home" {
  metadata {
    name = "smart-home"
  }
}
