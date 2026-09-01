module "arc" {
  source = "../../modules-harvester/actions-runner-controller"

  github_pat   = var.arc_github_pat
  repository   = var.arc_repository
  runner_image = local.images.arc_runner

  scale_sets = {
    # Heavy pool: E2E test jobs target e2e-self-hosted, release/deploy/image
    # build jobs target deploy-self-hosted (see infersec production-deploy.yml
    # and build-public-images.yml). Sized for llama.cpp + parallel suites -
    # module defaults apply.
    infersec-e2e = {
      labels      = ["e2e-self-hosted", "deploy-self-hosted"]
      max_runners = 4
    }

    # Light pool: unit/lint/smoke test jobs and website deploys target
    # ci-self-hosted (see infersec tests.yml and
    # production-deploy-website.yml) - no llama.cpp, no parallel browser
    # suites, so a much lower resource ceiling
    infersec-ci = {
      labels         = ["ci-self-hosted"]
      max_runners    = 4
      cpu_request    = "500m"
      cpu_limit      = "2000m"
      memory_request = "2Gi"
      memory_limit   = "4Gi"
    }
  }
}
