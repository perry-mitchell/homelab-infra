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

resource "kubernetes_namespace" "food" {
  metadata {
    name = "food"
  }
}

resource "kubernetes_namespace" "freelancing" {
  metadata {
    name = "freelancing"
  }
}

resource "kubernetes_namespace" "home_media" {
  metadata {
    name = "home-media"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "organisation" {
  metadata {
    name = "organisation"
  }
}

resource "kubernetes_namespace" "programming" {
  metadata {
    name = "programming"
  }
}

resource "kubernetes_namespace" "shared_data" {
  metadata {
    name = "shared-data"
  }
}

resource "kubernetes_namespace" "smart_home" {
  metadata {
    name = "smart-home"
  }
}

resource "kubernetes_namespace" "storage" {
  metadata {
    name = "storage"
  }
}

resource "kubernetes_namespace" "torrenting" {
  metadata {
    name = "torrenting"
  }
}

resource "kubernetes_namespace" "travel" {
  metadata {
    name = "travel"
  }
}
