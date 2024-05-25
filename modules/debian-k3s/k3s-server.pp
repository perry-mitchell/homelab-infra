exec { "create-rancher-dir":
    creates => "/etc/rancher/k3s",
    command => "mkdir -p /etc/rancher/k3s",
    path => ["/bin", "/usr/bin"],
}

file { "/etc/rancher/k3s/config.yaml":
    ensure => file,
    content => "${k3sConfig}",
    require => Exec["create-rancher-dir"]
}
