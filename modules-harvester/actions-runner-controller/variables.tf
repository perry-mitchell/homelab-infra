variable "github_pat" {
  description = "GitHub Personal Access Token used by the scale sets to register runners (needs Actions: read/write on the target repository)"
  type        = string
  sensitive   = true
}

variable "repository" {
  description = "GitHub repository to register runners against (owner/repo)"
  type        = string
  default     = "perry-mitchell/infersec"
}

variable "runner_image" {
  description = "Container image for the runner pods (uri + tag)"
  type = object({
    uri = string
    tag = string
  })
}

variable "controller_chart_version" {
  description = "Version of the gha-runner-scale-set-controller chart"
  type        = string
  default     = "0.14.2"
}

variable "scale_set_chart_version" {
  description = "Version of the gha-runner-scale-set chart"
  type        = string
  default     = "0.14.2"
}

variable "runner_namespace" {
  description = "Dedicated namespace for runner pods (listeners + ephemeral runners)"
  type        = string
  default     = "infersec-ci"
}

variable "scale_sets" {
  description = "Runner scale sets to create, keyed by release name. Labels are used by `runs-on` targeting; resource defaults are sized for the heavy e2e/deploy pool (llama.cpp + parallel suites)."
  type = map(object({
    labels         = list(string)
    min_runners    = optional(number, 0)
    max_runners    = optional(number, 2)
    cpu_request    = optional(string, "3000m")
    cpu_limit      = optional(string, "6000m")
    memory_request = optional(string, "12Gi")
    memory_limit   = optional(string, "14Gi")
  }))
}
