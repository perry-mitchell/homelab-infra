module "cert_manager" {
  source = "../../modules-harvester/cert-manager"

  letsencrypt_email  = var.letsencrypt_email
  ingress_service_ip = "10.53.200.80"
  public_hostnames   = var.public_domains
}

module "public_ingress" {
  source = "../../modules-harvester/public-ingress"

  cluster_ip = "10.53.200.80"

  depends_on = [module.cert_manager]
}
