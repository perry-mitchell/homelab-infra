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

##
## Repo setup
##

exec { "hashicorp-apt-key":
    path => $exec_path,
    command => 'curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg | gpg --dearmor | dd of=/usr/share/keyrings/hashicorp-archive-keyring.gpg',
    require => [
        Package["gpg"],
        Package["curl"]
    ]
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
## Consul
##

package { "consul":
    ensure => installed,
    require => Exec["hashicorp-apt-update"]
}

file { "/etc/consul.d/consul.hcl":
    ensure => file,
    content => "${consul_hcl}",
    notify => Service["consul"]
}

file { "/etc/consul.d/server.hcl":
    ensure => file,
    content => "${server_hcl}",
    notify => Service["consul"]
}

file { "/usr/lib/systemd/system/consul.service":
    ensure => file,
    content => "${consul_service}",
    notify => Service["consul"]
}

service { "consul":
    ensure  => true,
    enable  => true,
    require => [
        Package["consul"],
        File["/etc/consul.d/consul.hcl"],
        File["/etc/consul.d/server.hcl"],
        File["/usr/lib/systemd/system/consul.service"]
    ]
}

##
## dnsmasq
##

package { "dnsmasq":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

service { "dnsmasq":
    ensure  => true,
    enable  => true,
    require => [
        Package["dnsmasq"]
    ]
}

file { "/etc/dnsmasq.d/10-consul":
    ensure => file,
    content => "${ten_consul}",
    notify  => Service["dnsmasq"]
}
