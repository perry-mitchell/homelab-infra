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
