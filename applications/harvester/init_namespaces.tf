resource "kubernetes_namespace" "authentication" {
  metadata {
    name = "authentication"
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

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
