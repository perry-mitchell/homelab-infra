$exec_path = ["/bin", "/usr/bin"]

exec { "initial-apt-update":
    path => $exec_path,
    command => "apt-get update"
}

package { "curl":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

package { "gpg":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

package { "coreutils":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

##
## QEMU
##

package { "qemu-utils":
    ensure => installed,
    require => Exec["initial-apt-update"],
    notify => Service["nomad"]
}

package { "qemu-system-x86":
    ensure => installed,
    require => Exec["initial-apt-update"],
    notify => Service["nomad"]
}

package { "qemu-system-gui":
    ensure => installed,
    require => Exec["initial-apt-update"],
    notify => Service["nomad"]
}

##
## Repo setup
##

exec { "hashicorp-apt-key":
    path => $exec_path,
    command => 'curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg | gpg --dearmor | dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg',
    require => [
        Package["gpg"],
        Package["curl"]
    ],
    onlyif => ["test ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg"]
}

file { "/etc/apt/sources.list.d/hashicorp.list":
    ensure => file,
    content => "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main",
    require => Exec["hashicorp-apt-key"]
}

exec { "hashicorp-apt-update":
    path => $exec_path,
    command => "apt-get update",
    require => File["/etc/apt/sources.list.d/hashicorp.list"]
}

##
## Nomad
##

package { "nomad":
    ensure => installed,
    require => Exec["hashicorp-apt-update"]
}

file { "/etc/nomad.d/nomad.hcl":
    ensure => file,
    content => "${nomad_hcl}",
    notify => Service["nomad"]
}

file { "/etc/systemd/system/nomad.service":
    ensure => file,
    content => "${nomad_service}",
    notify => Service["nomad"]
}

service { "nomad":
    ensure  => true,
    enable  => true,
    require => [
        Package["nomad"],
        File["/etc/nomad.d/nomad.hcl"],
        File["/etc/systemd/system/nomad.service"]
    ]
}

##
## Nomad Plugins
##

exec { "nomad-cni-ref-plugins":
    path => $exec_path,
    provider => "shell",
    command => 'export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64) && export CNI_PLUGIN_VERSION=v1.5.1 && curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGIN_VERSION}/cni-plugins-linux-${ARCH_CNI}-${CNI_PLUGIN_VERSION}".tgz && mkdir -p /opt/cni/bin && tar -C /opt/cni/bin -xzf cni-plugins.tgz',
    notify => Service["nomad"]
}

package { "consul-cni":
    ensure => installed,
    require => [
        Exec["nomad-cni-ref-plugins"],
        Exec["hashicorp-apt-update"]
    ],
    notify => Service["nomad"]
}

package { "dmidecode":
    ensure => installed,
    require => Exec["initial-apt-update"],
    notify => Service["nomad"]
}

package { "nfs-common":
    ensure => installed,
    require => Exec["initial-apt-update"],
    notify => Service["nomad"]
}

##
## Docker
##

exec { "docker-apt-key":
    path => $exec_path,
    command => 'curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg',
    require => [
        Package["gpg"],
        Package["curl"]
    ],
    onlyif => ["test ! -f /usr/share/keyrings/docker.gpg"]
}

file { "/etc/apt/sources.list.d/docker.list":
    ensure => file,
    content => "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable",
    require => Exec["docker-apt-key"]
}

exec { "docker-apt-update":
    path => $exec_path,
    command => "apt-get update",
    require => [
        File["/etc/apt/sources.list.d/docker.list"],
        Exec["hashicorp-apt-update"]
    ]
}

package { "docker-ce":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
package { "docker-ce-cli":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
package { "containerd.io":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
package { "docker-buildx-plugin":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
package { "docker-compose-plugin":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
package { "docker-compose":
    ensure => installed,
    require => Exec["docker-apt-update"],
    notify => Service["nomad"]
}
