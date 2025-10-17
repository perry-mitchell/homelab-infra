provider "b2" {
  application_key    = var.backblaze_auth.application_key
  application_key_id = var.backblaze_auth.application_key_id
}

provider "cloudflare" {
  api_token = var.cloudflare_auth.api_token
}

provider "kubernetes" {
  config_path    = "./kube.config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path    = "./kube.config"
    config_context = "default"
  }
}

provider "namecheap" {
  user_name   = var.namecheap_auth.username
  api_user    = var.namecheap_auth.api_user
  api_key     = var.namecheap_auth.api_key
  client_ip   = var.namecheap_auth.client_ip
  use_sandbox = false
}

provider "pihole" {
  url      = var.pihole_url
  password = var.pihole_password
}
