variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
}

variable "public_ingress_class" {
  description = "IngressClass name for the public ingress controller (used in ACME HTTP-01 solver)"
  type        = string
  default     = "nginx-public"
}

variable "public_hostnames" {
  description = "Public hostnames that should resolve to the ingress controller internally (for ACME self-check)"
  type        = list(string)
  default     = []
}

variable "ingress_service_ip" {
  description = "Static ClusterIP of the public ingress controller service (for ACME self-check via hostAliases)"
  type        = string
  default     = null
}
