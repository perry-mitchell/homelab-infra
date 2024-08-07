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

exec { "create-consul-gossip-key":
    unless => "test -f /root/gossip.key",
    command => "consul keygen > /root/gossip.key",
    path => $exec_path,
    require => Package["consul"]
}
