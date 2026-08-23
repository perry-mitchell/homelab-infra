variable "github_pat" {
  description = "GitHub Personal Access Token used by the scale set to register runners (needs Actions: read/write on the target repository)"
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
  description = "Dedicated namespace for runner pods (listener + ephemeral runners)"
  type        = string
  default     = "infersec-ci"
}

variable "runner_labels" {
  description = "Labels applied to runners in the scale set (used by `runs-on`)"
  type        = list(string)
  default     = ["e2e-self-hosted"]
}

variable "min_runners" {
  description = "Minimum number of idle runner pods"
  type        = number
  default     = 0
}

variable "max_runners" {
  description = "Maximum number of concurrent runner pods"
  type        = number
  default     = 2
}

variable "runner_cpu_request" {
  description = "CPU request per runner pod"
  type        = string
  default     = "4"
}

variable "runner_memory_request" {
  description = "Memory request per runner pod"
  type        = string
  default     = "12Gi"
}
