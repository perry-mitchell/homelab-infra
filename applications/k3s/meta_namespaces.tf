resource "kubernetes_namespace" "backup" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "backup"
    }
}

resource "kubernetes_namespace" "business" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "business"
    }
}

resource "kubernetes_namespace" "datasources" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "datasources"
    }
}

resource "kubernetes_namespace" "dev" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "dev"
    }
}

resource "kubernetes_namespace" "entertainment" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "entertainment"
    }
}

resource "kubernetes_namespace" "family" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "family"
    }
}

resource "kubernetes_namespace" "monitoring" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "monitoring"
    }
}

resource "kubernetes_namespace" "remote_access" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "remote-access"
    }
}

resource "kubernetes_namespace" "security" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "security"
    }
}

resource "kubernetes_namespace" "smart_home" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "smart-home"
    }
}

resource "kubernetes_namespace" "torrents" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "torrents"
    }
}


resource "kubernetes_namespace" "travel" {
    depends_on = [ module.k3s_auth ]

    metadata {
        name = "travel"
    }
}
