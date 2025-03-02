resource "helm_release" "longhorn" {
    name       = "longhorn"
    namespace  = "longhorn-system"
    repository = "https://charts.longhorn.io"
    chart      = "longhorn"
    version    = "1.8.0"

    wait             = true
    create_namespace = true

    values = [
        yamlencode({})
    ]
}
