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

file { "/usr/lib/systemd/system/consul.service":
    ensure => file,
    content => "${consul_service}",
    notify => Service["consul"]
}

file { "/opt/consul":
    ensure => directory,
    owner => "consul",
    group => "consul",
    notify => Service["consul"]
}

service { "consul":
    ensure  => running,
    enable  => true,
    require => [
        Package["consul"],
        File["/opt/consul"],
        File["/etc/consul.d/consul.hcl"],
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
    ensure  => running,
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
