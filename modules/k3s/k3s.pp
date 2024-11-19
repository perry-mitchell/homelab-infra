$exec_path = ["/bin", "/usr/bin"]
$k3s_download = "https://github.com/k3s-io/k3s/releases/download/v1.26.5+k3s1/k3s"
$k3s_binary = "/usr/local/bin/k3s"

file { ["/etc/rancher", "/etc/rancher/k3s"]:
    ensure => directory,
    owner => "root",
    group => "root",
    mode => "0755"
}

file { "/etc/rancher/k3s/config.yaml":
    ensure => file,
    content => "${config_yaml}",
    require => File["/etc/rancher/k3s"],
    notify => Service["k3s"]
}

archive { $k3s_binary:
    ensure => present,
    source => $k3s_download,
    user => "root",
    group => "root",
}

exec { "k3s-executable":
    path => $exec_path,
    command => "chmod a+x ${$k3s_binary}",
    require => Archive[$k3s_binary],
    subscribe => Archive[$k3s_binary],
    notify => Service["k3s"],
}

file { "/etc/systemd/system/k3s.service":
    ensure => file,
    content => "${k3s_service}",
}

service { "k3s":
    ensure  => running,
    enable  => true,
    require => [
        Archive[$k3s_binary],
        Exec["k3s-executable"],
        File["/etc/systemd/system/k3s.service"],
        File["/etc/rancher/k3s/config.yaml"]
    ]
}
