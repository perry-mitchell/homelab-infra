$exec_path = ["/bin", "/usr/bin"]
$k3s_download = "https://github.com/k3s-io/k3s/releases/download/v1.32.1+k3s1/k3s"
$k3s_binary = "/usr/local/bin/k3s"

exec { "set-hostname":
    path => $exec_path,
    command => "hostnamectl set-hostname ${node_hostname}"
}

exec { "initial-apt-update":
    path => $exec_path,
    command => "apt-get update"
}

package { "nfs-common":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

package { "wget":
    ensure => installed,
    require => Exec["initial-apt-update"]
}



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

exec { "k3s-download":
    path => $exec_path,
    command => "wget -q -O /tmp/k3s ${k3s_download}",
    require => Package["wget"]
}

exec { "k3s-executable":
    path => $exec_path,
    command => "mv /tmp/k3s ${k3s_binary} && chown root:root ${k3s_binary} && chmod a+x ${$k3s_binary}",
    unless => "test -f ${k3s_binary}",
    require => Exec["k3s-download"],
    subscribe => Exec["k3s-download"],
    notify => Service["k3s"]
}

file { "/etc/systemd/system/k3s.service":
    ensure => file,
    content => "${k3s_service}",
}

service { "k3s":
    ensure  => running,
    enable  => true,
    require => [
        Exec["k3s-executable"],
        File["/etc/systemd/system/k3s.service"],
        File["/etc/rancher/k3s/config.yaml"]
    ]
}
