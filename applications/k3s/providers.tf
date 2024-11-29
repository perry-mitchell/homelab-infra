provider "kubernetes" {
    config_path    = "./kube.config"
    config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path = "./kube.config"
    config_context = "default"
  }
}

provider "pihole" {
    url = var.pihole_url
    password = var.pihole_password
}

provider "mysql" {
    endpoint = "${local.mariadb_service_hostname}:3306"
    username = "root"
    password = var.db_mariadb_root
}
