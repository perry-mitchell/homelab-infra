resource "helm_release" "longhorn" {
    name       = "longhorn"
    namespace  = "longhorn-system"
    repository = "https://charts.longhorn.io"
    chart      = "longhorn"
    version    = "1.8.0"

    wait             = true
    create_namespace = true

    values = [
        yamlencode({
            # longhornManager = {
            #     serviceAnnotations = {
            #         "tailscale.com/expose"   = "true"
            #         "tailscale.com/hostname" = var.tailscale.hostname
            #     }
            # }
            # ingress = {
            #     enabled = true
            #     ingressClassName = "tailscale"
            #     annotations = {
            #         "tailscale.com/expose"   = "true"
            #         "tailscale.com/hostname" = var.tailscale.hostname
            #     }
            #     host = ""
            #     # path = "/"
            #     # pathType = "Prefix"
            # }
        })
    ]

    # set {
    #     name = "ingress.enabled"
    #     value = "true"
    # }

    # set {
    #     name = "ingress.ingressClassName"
    #     value = "tailscale"
    # }

    # # set {
    # #     name = "ingress.annotations[\"tailscale.com/expose\"]"
    # #     value = "true"
    # # }

    # # set {
    # #     name = "ingress.annotations[\"tailscale.com/hostname\"]"
    # #     value = var.tailscale.hostname
    # # }

    # set {
    #     name = "ingress.host"
    #     value = module.dns_tailscale.dns_name
    # }
}
