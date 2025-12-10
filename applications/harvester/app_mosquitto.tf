module "app_mosquitto" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    mosquitto = {
      environment = {
        TZ = "Europe/Helsinki"
      }
      image = {
        tag = "2"
        uri = "eclipse-mosquitto"
      }
      longhorn_mounts = {
        data = {
          container_path  = "/mosquitto/data"
          storage_request = "10Gi"
        }
        logs = {
          container_path  = "/mosquitto/log"
          storage_request = "15Gi"
        }
      }
      ports = [
        {
          container         = 1883
          internal_hostname = "mosquitto"
          service           = 1883
        }
      ]
      static_mounts = {
        "/mosquitto/config/mosquitto.conf" = file("${path.module}/config/mosquitto/mosquitto.conf")
      }
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "mosquitto"
  namespace              = kubernetes_namespace.smart_home.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
