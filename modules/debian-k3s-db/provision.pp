exec { "initial-apt-update":
    path => ["/bin", "/usr/bin"],
    command => "apt-get update"
}

package { "gpg":
    ensure => installed,
    require => Exec["initial-apt-update"]
}

##
## MySQL apt config
##

exec { "mysql-apt-key":
    path => ["/bin", "/usr/bin"],
    command => "gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mysql-server.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B7B3B788A8D3785C",
    require => Package["gpg"]
}

file { "/etc/apt/sources.list.d/mysql-server.list":
    ensure => file,
    content => "deb [signed-by=/usr/share/keyrings/mysql-server.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-8.0"
}

exec { "mysql-apt-update":
    path => ["/bin", "/usr/bin"],
    command => "apt-get update",
    require => [
        Exec["mysql-apt-key"],
        File["/etc/apt/sources.list.d/mysql-server.list"]
    ]
}


##
## MySQL server install
##

package { "mysql-server":
    ensure => installed,
    require => Exec["mysql-apt-update"]
}

file_line { "mysqld-listen-interface":
    path => "/etc/mysql/mysql.conf.d/mysqld.cnf",
    line => "bind-address=0.0.0.0",
    require => Package["mysql-server"],
    notify  => Service["mysql"]
}

service { "mysql":
    ensure  => true,
    enable  => true,
    require => [
        Package["mysql-server"],
        File_line["mysqld-listen-interface"]
    ]
}

exec { "set-mysql-root-password":
    unless => "mysqladmin -uroot -p${mysqlRootPassword} status",
    command => "mysqladmin -uroot password \"${mysqlRootPassword}\"",
    path => ["/bin", "/usr/bin"],
    require => Service["mysql"]
}

exec { "allow-external-access":
    command => "mysql -uroot -p${mysqlRootPassword} -e 'UPDATE mysql.user SET host=\"%\" WHERE user=\"root\"; ALTER USER root@\"%\" IDENTIFIED WITH mysql_native_password BY \"${mysqlRootPassword}\"; FLUSH PRIVILEGES;'",
    path => ["/bin", "/usr/bin"],
    require => [
        Service["mysql"],
        Exec["set-mysql-root-password"]
    ]
}
