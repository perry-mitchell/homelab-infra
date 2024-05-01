# Perry's Homelab Infrastructure

> OpenTofu + Puppet configuration for my homelab

## About

This is a infra-as-code representation of the newer portion of my **homelab**. It uses Opentofu and Puppet to provision applications and servers.

### Requirements

This project assumes you already have X servers ready for provisioning via this configuration (`/applications/main`), based on **Debian 12**. You need 1 server for the k3s database (HA).

You additionally need another postgres database for tofu state.

## Usage

Ensure you have the latest `tofu` executable installed.

Export a postgres connection string:

```shell
export PG_CONN_STR=postgres://user:pass@server:5432/db
```

Change directory to `application/main` and ensure that there's a completed `terraform.tfvars` file:

```terraform
k3s_database_password = "pass"

k3s_database_root_password = "pass"

k3s_database_username = "k3smaster"

k3s_database_server = {
    ip = "ip"
    password = ""
    user = "root"
    work_dir = "/root"
}

k3s_servers = {
    example1 = {
        ip = "ip1"
        password = ""
        user = "root"
        work_dir = "/root"
    }
    example2 = {
        ip = "ip2"
        password = ""
        user = "root"
        work_dir = "/root"
    }
}
```

Run `tofu init` to get started. After init run `tofu apply` to start provisioning.
