variable "github_pat" {
  description = "GitHub Personal Access Token for ARC runner authentication"
  type        = string
  sensitive   = true
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
}

variable "longhorn_storage_class" {
  description = "Storage class for PVCs"
  type        = string
}

variable "repository" {
  description = "GitHub repository to target (owner/repo)"
  type        = string
}

variable "runner_image" {
  description = "Container image for the runner (uri + tag)"
  type = object({
    uri = string
    tag = string
  })
}

variable "runner_labels" {
  description = "Labels for the runner"
  type        = list(string)
  default     = ["e2e-self-hosted"]
}

variable "runner_namespace" {
  description = "Namespace for runner pods"
  type        = string
  default     = "arc-runners"
}

variable "runner_replicas" {
  description = "Number of runner replicas"
  type        = number
  default     = 1
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

variable "npm_cache_storage" {
  description = "Storage request for npm cache PVC"
  type        = string
  default     = "10Gi"
}

variable "general_cache_storage" {
  description = "Storage request for general cache PVC (Playwright, llama.cpp)"
  type        = string
  default     = "20Gi"
}
