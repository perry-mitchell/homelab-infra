provider "b2" {
    application_key = var.backblaze_auth.application_key
    application_key_id = var.backblaze_auth.application_key_id
}

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
