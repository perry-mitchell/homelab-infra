###############################################################################
# WorkAdventure - 2D pixel "virtual office" with proximity-based video calls
#
# WHAT THIS FILE DEPLOYS
# ----------------------
# 1. helm_release "workadventure"
#    The official WorkAdventure chart (charts.workadventu.re), pinned to a
#    release-aligned version (chart version == WorkAdventure version). Runs in
#    single-domain mode on "wa.<public_domain>" behind the nginx-public ingress
#    with LetsEncrypt certs (cert-manager ingress shim). The chart deploys:
#      - play       (frontend assets + pusher websocket, sticky sessions on)
#      - back       (room state / signalling)
#      - uploader   (file uploads for chat)
#      - mapstorage (serves + stores uploaded maps, Longhorn PVC, bearer token
#                    auth for uploads via MAP_STORAGE_API_TOKEN)
#      - icon       (favicon fetcher for embedded sites)
#      - redis      (chart-managed, non-persistent, internal only)
#    plus the LiveKit subchart (see below).
#
# 2. LiveKit (chart subchart, hostNetwork)
#    Selective forwarding unit for group calls. Bubbles with more than
#    MAX_USERS_FOR_WEBRTC (4) participants switch from browser-to-browser P2P
#    WebRTC to LiveKit; the browser gets the URL from LIVEKIT_HOST.
#    Signalling (wss) runs over HTTPS through nginx-public on the SAME host
#    (wa.<public_domain>): the chart-managed livekit ingress is disabled and
#    kubernetes_ingress_v1.workadventure_livekit below routes the "/rtc" path
#    to the "workadventure-livekit-server" service. This reuses the
#    "workadventure-cert" TLS secret - no extra hostname or certificate.
#    The MEDIA plane (UDP) CANNOT go through a Kubernetes Service:
#    ICE/STUN requires the server to answer on the exact IP:port it
#    advertised, NodePort remaps ports and kube-proxy NAT breaks it. LiveKit's
#    own Helm chart therefore defaults to host networking (podHostNetwork),
#    limited to one pod per node, pinned here via nodeSelector to a single
#    node with a static management-network IP ("workadventure_media_node").
#    UDP media range is shrunk to 50000-50049 (50 concurrent streams).
#    "use_external_ip" (subchart default) makes LiveKit discover the router's
#    public IP via STUN and advertise it, so dynamic public IPs are tolerated.
#
# 3. Coturn (kubernetes_deployment, hostNetwork, same pinned node)
#    TURN relay for P2P (<=4 person) calls when a browser is behind a NAT that
#    blocks direct connections. Listens on 3478/udp+tcp and 5349/tcp (TLS,
#    "turns:" scheme, cert from cert-manager with SAN = the WA hostname - so
#    no dedicated turn.<domain> DNS record or certificate is needed).
#    Relay port range 49160-49200/udp. Uses a static auth secret shared with
#    WorkAdventure (TURN_STATIC_AUTH_SECRET) - WorkAdventure mints short-lived
#    TURN credentials in the browser, so no username/password is exposed.
#    The public IP is dynamic, so the container resolves the WA hostname
#    (kept up to date by ddclient) at startup and appends "external-ip" to
#    its runtime config. Caveat: on a public IP change the pod must be
#    restarted to re-resolve.
#
# AUTHENTICATION
# --------------
# Access is public-internet + OIDC-gated. Authentik (see app_authentik.tf at
# "auth.<public_domain>") is the identity provider. Until
# workadventure.oidc_client_id / oidc_client_secret are filled in
# terraform.tfvars, the instance runs anonymous (anyone with the URL can
# enter). To enable the login gate:
#   1. tofu apply (Authentik comes up)
#   2. In Authentik: create an OAuth2 provider + application named
#      "workadventure" (authorization code + PKCE), redirect URI:
#      https://wa.<public_domain>/openid-callback
#   3. Put the client id/secret into terraform.tfvars and apply again - this
#      enables OPENID_CLIENT_* env vars and DISABLE_ANONYMOUS.
#
# PREREQUISITES / MANUAL STEPS (outside this repo)
# ------------------------------------------------
#   DNS records (like radicale.<public_domain>): "wa" and "auth" ->
#     public IP (ddclient keeps them current).
#   Router port-forwards -> the pinned media node's static IP:
#       7881/udp, 50000-50049/udp   (LiveKit media)
#       3478/udp+tcp, 5349/tcp      (Coturn)
#       49160-49200/udp             (Coturn relay)
#     80/443 already forwarded to the cluster (public ingress NodePorts).
#
# OPERATIONS
# ----------
#   All replicas are wired to local.deployments_enabled (shutdown flow).
#   Map uploads: use the map-starter-kit (github.com/workadventure/
#   map-starter-kit) against https://wa.<public_domain>/map-storage/ with
#   workadventure.map_storage_api_token. The default start room is the public
#   starter-kit office map; override START_ROOM_URL after uploading your own.
#   Upgrades: chart versions track WorkAdventure releases; read the release
#   notes + compare values.yaml before bumping (no backward-compatibility
#   guarantee between minor versions).
###############################################################################

locals {
  workadventure_host         = "wa.${var.public_domain}"
  workadventure_oidc_issuer  = "https://auth.${var.public_domain}/application/o/workadventure/"
  workadventure_media_node   = "torrens4"
  workadventure_oidc_enabled = var.workadventure.oidc_client_id != "" && var.workadventure.oidc_client_secret != ""
}

resource "random_password" "workadventure_room_api" {
  length  = 32
  special = false
}

resource "helm_release" "workadventure" {
  name      = "workadventure"
  namespace = kubernetes_namespace.entertainment.metadata.0.name

  repository = "https://charts.workadventu.re"
  chart      = "workadventure"
  version    = "v1.33.5"
  wait       = false

  values = [
    yamlencode({
      domainName   = local.workadventure_host
      singleDomain = true

      ingress = {
        enabled    = true
        className  = "nginx-public"
        tls        = true
        secretName = "workadventure-cert"
        annotationsRoot = {
          "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
        }
        annotationsPath = {
          "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
          "nginx.ingress.kubernetes.io/use-regex"      = "true"
          "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
        }
      }

      commonEnv = {
        MAX_USERS_FOR_WEBRTC = "4"
        TURN_SERVER          = "turns:${local.workadventure_host}:5349"
      }

      commonSecretEnv = {
        MAP_STORAGE_API_TOKEN   = var.workadventure.map_storage_api_token
        TURN_STATIC_AUTH_SECRET = var.workadventure.turn_static_secret
      }

      livekit = {
        enabled     = true
        host        = "https://${local.workadventure_host}"
        serviceName = "workadventure-livekit-server"
        ingress = {
          enabled = false
        }
      }

      livekit-server = {
        replicaCount = local.deployments_enabled.service ? 1 : 0
        nodeSelector = {
          "kubernetes.io/hostname" = local.workadventure_media_node
        }
        livekit = {
          rtc = {
            port_range_start = 50000
            port_range_end   = 50049
          }
        }
      }

      play = {
        replicaCount = local.deployments_enabled.service ? 1 : 0
        ingress = {
          sticky = {
            enabled = true
          }
        }
        env = local.workadventure_oidc_enabled ? {
          DISABLE_ANONYMOUS    = "true"
          OPENID_CLIENT_ISSUER = local.workadventure_oidc_issuer
        } : {}
        secretEnv = merge(
          {
            ROOM_API_SECRET_KEY = random_password.workadventure_room_api.result
          },
          local.workadventure_oidc_enabled ? {
            OPENID_CLIENT_ID     = var.workadventure.oidc_client_id
            OPENID_CLIENT_SECRET = var.workadventure.oidc_client_secret
          } : {}
        )
      }

      back = {
        replicaCount = local.deployments_enabled.service ? 1 : 0
      }

      uploader = {
        replicaCount = local.deployments_enabled.service ? 1 : 0
      }

      mapstorage = {
        replicaCount = local.deployments_enabled.service ? 1 : 0
        persistence = {
          enabled      = true
          storageClass = var.longhorn_storage_class
          storageSize  = "5Gi"
        }
        env = {
          ENABLE_BEARER_AUTHENTICATION = "true"
        }
        secretEnv = {
          AUTHENTICATION_PASSWORD = var.workadventure.map_storage_password
        }
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "workadventure_livekit" {
  metadata {
    name      = "workadventure-livekit"
    namespace = kubernetes_namespace.entertainment.metadata.0.name
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-read-timeout" = "3600"
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "3600"
    }
  }

  spec {
    ingress_class_name = "nginx-public"

    tls {
      hosts       = [local.workadventure_host]
      secret_name = "workadventure-cert"
    }

    rule {
      host = local.workadventure_host

      http {
        path {
          path      = "/rtc"
          path_type = "Prefix"

          backend {
            service {
              name = "workadventure-livekit-server"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "coturn_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "coturn"
      namespace = kubernetes_namespace.entertainment.metadata.0.name
    }
    spec = {
      secretName = "coturn-tls"
      dnsNames   = [local.workadventure_host]
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
    }
  }
}

resource "kubernetes_secret" "coturn_config" {
  metadata {
    name      = "coturn-config"
    namespace = kubernetes_namespace.entertainment.metadata.0.name
  }

  data = {
    "turnserver.conf" = <<-EOT
      listening-port=3478
      tls-listening-port=5349
      fingerprint
      lt-cred-mech
      use-auth-secret
      static-auth-secret=${var.workadventure.turn_static_secret}
      realm=${local.workadventure_host}
      cert=/etc/coturn/tls/tls.crt
      pkey=/etc/coturn/tls/tls.key
      min-port=49160
      max-port=49200
      no-cli
      no-multicast-peers
      no-tlsv1
      no-tlsv1_1
    EOT
  }
}

resource "kubernetes_deployment" "coturn" {
  metadata {
    name      = "coturn"
    namespace = kubernetes_namespace.entertainment.metadata.0.name
  }

  spec {
    replicas = local.deployments_enabled.service ? 1 : 0

    selector {
      match_labels = {
        application = "coturn"
      }
    }

    template {
      metadata {
        labels = {
          application = "coturn"
        }
      }

      spec {
        host_network = true
        dns_policy   = "ClusterFirstWithHostNet"
        node_selector = {
          "kubernetes.io/hostname" = local.workadventure_media_node
        }

        container {
          name  = "coturn"
          image = "${local.images.coturn.uri}:${local.images.coturn.tag}"

          command = ["/bin/sh", "-c"]
          args = [
            "EXTERNAL_IP=$(getent hosts ${local.workadventure_host} | awk '{print $1}') && cp /etc/coturn-config/turnserver.conf /tmp/turnserver.conf && echo \"external-ip=$EXTERNAL_IP\" >> /tmp/turnserver.conf && exec turnserver -c /tmp/turnserver.conf"
          ]

          volume_mount {
            name       = "config"
            mount_path = "/etc/coturn-config"
            read_only  = true
          }

          volume_mount {
            name       = "tls"
            mount_path = "/etc/coturn/tls"
            read_only  = true
          }
        }

        volume {
          name = "config"
          secret {
            secret_name = kubernetes_secret.coturn_config.metadata[0].name
          }
        }

        volume {
          name = "tls"
          secret {
            secret_name = kubernetes_manifest.coturn_certificate.manifest.spec.secretName
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"]
    ]
  }
}
