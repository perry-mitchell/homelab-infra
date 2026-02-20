variable "cluster_ip" {
  description = "Static ClusterIP for the ingress controller service (must be within the cluster service CIDR)"
  type        = string
}
