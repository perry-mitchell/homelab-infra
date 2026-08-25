module "arc" {
  source = "../../modules-harvester/actions-runner-controller"

  github_pat   = var.arc_github_pat
  repository   = var.arc_repository
  runner_image = local.images.arc_runner

  # Two E2E jobs (console + selfhosted) per PR, plus headroom for a
  # concurrent branch before jobs start queuing
  max_runners = 4
}
