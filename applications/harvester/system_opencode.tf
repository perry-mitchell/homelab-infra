resource "kubernetes_namespace" "system" {
  metadata {
    name = "system"
  }
}

module "system_opencode" {
  source = "../../modules-harvester/virtual-machine"

  name      = "opencode"
  namespace = kubernetes_namespace.programming.metadata[0].name
  cpu       = 4
  memory    = "10Gi"
  disk_size = "100Gi"

  image_url       = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  image_name      = "ubuntu-2404"
  image_namespace = "harvester-public"

  cloud_init_user_data = <<-EOF
    #cloud-config
    package_update: true
    ssh_pwauth: false
    packages:
      - git
      - curl
      - wget
      - qemu-guest-agent
      - openssh-server
    users:
      - name: opencode
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
%{ for key in var.opencode_ssh_public_keys ~}
          - ${key}
%{ endfor ~}
    runcmd:
      - [systemctl, enable, --now, qemu-guest-agent]
  EOF

  tailscale_hostname = "opencode"
  k8s_namespace      = kubernetes_namespace.programming.metadata[0].name
  service_port       = 80
  target_port        = 4096

  tags = { ssh-user = "opencode" }
}
