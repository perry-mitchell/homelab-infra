# Perry's Homelab Infrastructure

> OpenTofu + Puppet configuration for my homelab

## About

This is a infra-as-code representation of the newer portion of my **homelab**. It uses Opentofu and Puppet to provision applications and servers.

### Requirements

This project assumes you already have X servers ready for provisioning via this configuration (`/applications/k3s`), based on **Debian 12**.

You need to have the local software installed:

 * OpenTofu CLI
 * `sshpass`

## Usage

Export a postgres connection string:

```shell
export PG_CONN_STR=postgres://user:pass@server:5432/db
```

Change directory to `application/k3s` and ensure that there's a completed `terraform.tfvars` file:

```hcl
<TBA>
```

Run `tofu init` to get started. After init run `tofu apply` to start provisioning.
