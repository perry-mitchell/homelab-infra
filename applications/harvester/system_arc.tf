module "arc" {
  source = "../../modules-harvester/actions-runner-controller"

  github_pat              = var.arc_github_pat
  kubeconfig_path         = "./kube.config"
  longhorn_storage_class  = var.longhorn_storage_class
  repository              = "perry-mitchell/infersec"
  runner_image            = local.images.arc_runner
}
