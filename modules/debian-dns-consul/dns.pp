$exec_path = ["/bin", "/usr/bin", "/usr/sbin"]

package { "resolvconf":
    ensure => installed
}

# file { "/etc/consul.d/consul.hcl":
#     ensure => file,
#     content => "${consul_hcl}",
#     notify => Service["consul"]
# }

file_line { "nameserver":
    path => "/etc/resolvconf/resolv.conf.d/head",
    line => "nameserver ${dns_server}",
    notify => [
        Service["resolvconf"],
        Exec["resolvconf-update"]
    ]
}

##
## Service
##

service { "resolvconf":
    ensure  => running,
    enable  => true,
    require => [
        Package["resolvconf"],
        File_Line["nameserver"],
    ]
}

exec { "resolvconf-update":
    path => $exec_path,
    command => "resolvconf -u",
    require => [
        File_Line["nameserver"],
        Service["resolvconf"]
    ]
}
