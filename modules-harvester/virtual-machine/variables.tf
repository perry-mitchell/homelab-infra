variable "name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = string
}

variable "disk_size" {
  type = string
}

variable "disk_bus" {
  type    = string
  default = "virtio"
}

variable "image_id" {
  type    = string
  default = null
}

variable "image_url" {
  type    = string
  default = null
}

variable "image_name" {
  type    = string
  default = null
}

variable "image_namespace" {
  type    = string
  default = "harvester-public"
}

variable "cloud_init_user_data" {
  type    = string
  default = null
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}

variable "run_strategy" {
  type    = string
  default = "RerunOnFailure"
}

variable "efi" {
  type    = bool
  default = true
}

variable "restart_after_update" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "tailscale_hostname" {
  type    = string
  default = null
}

variable "k8s_namespace" {
  type    = string
  default = null
}

variable "service_port" {
  type    = number
  default = 80
}

variable "target_port" {
  type    = number
  default = 80
}

variable "enable_live_migration" {
  description = "Patch the kubevirt VM template with kubevirt.io/allow-pod-bridge-network-live-migration so bridge-networked VMs can be live-migrated during node drains (e.g. Harvester upgrades)."
  type        = bool
  default     = true
}
