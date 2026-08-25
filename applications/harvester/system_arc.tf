module "arc" {
  source = "../../modules-harvester/actions-runner-controller"

  github_pat   = var.arc_github_pat
  repository   = var.arc_repository
  runner_image = local.images.arc_runner

  # Same pool serves both audiences via separate labels: E2E test jobs
  # target e2e-self-hosted, release/deploy/image-build jobs target
  # deploy-self-hosted (see infersec production-deploy.yml and
  # build-public-images.yml)
  runner_labels = ["e2e-self-hosted", "deploy-self-hosted"]

  # Two E2E jobs (console + selfhosted) per PR, plus deploy/build work and
  # headroom before jobs start queuing
  max_runners = 4
}
