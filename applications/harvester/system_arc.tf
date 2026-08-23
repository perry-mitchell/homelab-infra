module "arc" {
  source = "../../modules-harvester/actions-runner-controller"

  github_pat   = var.arc_github_pat
  repository   = var.arc_repository
  runner_image = local.images.arc_runner
}
