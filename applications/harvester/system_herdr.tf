module "system_herdr" {
  source = "../../modules-harvester/virtual-machine"

  name      = "herdr"
  namespace = kubernetes_namespace.programming.metadata[0].name
  cpu       = 4
  memory    = "12Gi"
  disk_size = "100Gi"

  image_id = "harvester-public/ubuntu-2404"

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
      - name: herdr
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
%{for key in var.herdr_ssh_public_keys~}
          - ${key}
%{endfor~}
    write_files:
%{if var.herdr_infersec_api_key != ""~}
      - path: /home/herdr/.omp/agent/models.yml
        owner: herdr:herdr
        defer: true
        content: |
          providers:
            infersec:
              baseUrl: https://api.infersec.ai/api/inferencing/01kzveapanh78400ec7qxbce20/oai/v1
              api: openai-completions
              apiKey: ${var.herdr_infersec_api_key}
              models:
                - id: default
                  name: default
                  contextWindow: 256000
                  maxTokens: 32000
%{endif~}
      - path: /usr/local/bin/herdr-bootstrap
        permissions: "0755"
        content: |
          #!/bin/bash
          set -eu
          curl -fsSL https://tailscale.com/install.sh | sh
%{if var.tailscale_vm_auth_key != ""~}
          tailscale up --authkey=${var.tailscale_vm_auth_key} --hostname=herdr --accept-dns=false
%{endif~}
          sudo -u herdr sh -c 'curl -fsSL https://herdr.dev/install.sh | sh'
          sudo -u herdr sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
          sudo -u herdr sh -c 'curl -fsSL https://opencode.ai/install | bash'
          sudo -u herdr sh -c 'curl -fsSL https://omp.sh/install | sh'
    runcmd:
      - [systemctl, enable, --now, qemu-guest-agent]
      - [/usr/local/bin/herdr-bootstrap]
  EOF

  tags = { ssh-user = "herdr" }
}
