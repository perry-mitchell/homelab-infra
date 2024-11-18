$exec_path = ["/bin", "/usr/bin", "/usr/sbin"]

package { "resolvconf":
    ensure => purged
}

file { "/etc/resolve.conf":
    ensure => absent
}

package { "systemd-resolved":
    ensure => installed
}

file { "/etc/systemd/resolved.conf":
#file { "/etc/systemd/resolved.conf.d/consul.conf":
    ensure => file,
    content => "[Resolve]\nDNS=127.0.0.1:8600\nDNSSEC=false\nDomains=~consul\nFallbackDNS=8.8.8.8\n"
    #content => "[Resolve]\nDNS=1.1.1.1\nDomains=~.\n"
}









# file { "/etc/consul.d/consul.hcl":
#     ensure => file,
#     content => "${consul_hcl}",
#     notify => Service["consul"]
# }

#file_line { "nameserver":
#    path => "/etc/resolvconf/resolv.conf.d/head",
#    line => "nameserver ${dns_server}",
#    notify => [
#        Service["resolvconf"],
#        Exec["resolvconf-update"]
#    ],
#    ensure => absent
#}

#file { "/etc/systemd/resolved.conf.d/consul.conf":
#    ensure => file,
#    content => "[Resolve]\nDNS=127.0.0.1:8600\nDNSSEC=false\nDomains=~consul\n"
#}

##
## Service
##

#service { "resolvconf":
#    ensure  => running,
#    enable  => true,
#    require => [
#        Package["resolvconf"],
#        #File_Line["nameserver"],
#    ]
#}

#exec { "resolvconf-update":
#    path => $exec_path,
#    command => "resolvconf -u",
#    require => [
#        #File_Line["nameserver"],
#        Service["resolvconf"]
#    ]
#}
