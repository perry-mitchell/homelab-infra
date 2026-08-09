resource "random_password" "infersec_s3_access_key" {
  length  = 20
  special = false
}

resource "random_password" "infersec_s3_secret_key" {
  length  = 40
  special = false
}

locals {
  infersec_s3 = {
    access_key = random_password.infersec_s3_access_key.result
    bucket     = "infersec"
    endpoint   = "http://versity:7070"
    region     = "us-east-1"
    secret_key = random_password.infersec_s3_secret_key.result
  }
}

module "db_infersec_mariadb" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "infersec-mariadb" = {
      environment = {
        MARIADB_ROOT_PASSWORD = var.db_mariadb_root
        TZ                    = "Europe/Helsinki"
      }
      image = local.images.mariadb
      longhorn_mounts = {
        mysql = {
          container_path  = "/var/lib/mysql"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 3306
          internal_hostname = "infersec-mariadb"
          service           = 3306
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "infersec-mariadb"
  namespace              = kubernetes_namespace.infersec.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

resource "random_password" "infersec_database_user" {
  length  = 32
  special = false
}

module "db_init_infersec" {
  source = "../../modules-harvester/mysql-init"

  depends_on = [module.db_infersec_mariadb]

  create_database = "infersec"
  create_user = {
    password = random_password.infersec_database_user.result
    username = "infersec"
  }
  db_host     = "infersec-mariadb"
  db_password = var.db_mariadb_root
  db_username = "root"
  grant_users = {
    "infersec" = "infersec"
  }
  name      = "infersec"
  namespace = kubernetes_namespace.infersec.metadata.0.name
}

module "db_infersec_redis" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "infersec-redis" = {
      environment = {
        ALLOW_EMPTY_PASSWORD = "no"
        REDIS_PASSWORD       = var.db_redis_root
      }
      fs_group = 1001
      image    = local.images.redis
      longhorn_mounts = {
        data = {
          container_path  = "/bitnami/redis/data"
          storage_request = "10Gi"
        }
      }
      ports = [
        {
          container         = 6379
          internal_hostname = "infersec-redis"
          service           = 6379
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "infersec-redis"
  namespace              = kubernetes_namespace.infersec.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

module "db_infersec_versity" {
  source = "../../modules-harvester/service"

  cluster_name = var.cluster_name
  containers = {
    "infersec-versity" = {
      command = ["/bin/sh", "-c"]
      args    = ["mkdir -p /data/${local.infersec_s3.bucket} && exec /usr/local/bin/versitygw --port :7070 posix /data"]
      environment = {
        ROOT_ACCESS_KEY = local.infersec_s3.access_key
        ROOT_SECRET_KEY = local.infersec_s3.secret_key
      }
      image = local.images.versity
      longhorn_mounts = {
        data = {
          container_path  = "/data"
          storage_request = "20Gi"
        }
      }
      ports = [
        {
          container         = 7070
          internal_hostname = "versity"
          service           = 7070
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "infersec-versity"
  namespace              = kubernetes_namespace.infersec.metadata.0.name
  replicas               = local.deployments_enabled.datasource ? 1 : 0
}

module "app_infersec" {
  source = "../../modules-harvester/service"

  depends_on = [module.db_init_infersec, module.db_infersec_redis, module.db_infersec_versity]

  cluster_name = var.cluster_name
  containers = {
    selfhosted = {
      environment = {
        DB_PRIMARY_DATABASE        = "infersec"
        DB_PRIMARY_HOST            = "infersec-mariadb"
        DB_PRIMARY_PASSWORD        = random_password.infersec_database_user.result
        DB_PRIMARY_PORT            = "3306"
        DB_PRIMARY_USER            = "infersec"
        HTTPS                      = "true"
        INFERSEC_SECRET_MASTER_KEY = var.infersec.master_key
        LICENSE_KEY                = var.infersec.license_key
        REDIS_API_CACHE_DB         = "2"
        REDIS_DB                   = "0"
        REDIS_HOST                 = "infersec-redis"
        REDIS_LOCK_DB              = "1"
        REDIS_PASSWORD             = var.db_redis_root
        REDIS_PORT                 = "6379"
        S3_ACCESS_KEY_ID           = local.infersec_s3.access_key
        S3_BUCKET                  = local.infersec_s3.bucket
        S3_ENDPOINT                = local.infersec_s3.endpoint
        S3_REGION                  = local.infersec_s3.region
        S3_SECRET_ACCESS_KEY       = local.infersec_s3.secret_key
        SELFHOSTED_PUBLIC_URL      = var.infersec.public_url
        SESSION_SECRET             = var.infersec.session_secret
      }
      hostname = "infersec-selfhosted"
      image    = local.images.infersec
      ports = [
        {
          container          = 9507
          service            = 80
          tailscale_hostname = "infersec"
        }
      ]
    }
  }
  longhorn_storage_class = var.longhorn_storage_class
  name                   = "infersec"
  namespace              = kubernetes_namespace.infersec.metadata.0.name
  replicas               = local.deployments_enabled.service ? 1 : 0
}
