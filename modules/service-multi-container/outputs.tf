output "host_k8s" {
  value = {
    for name, container in var.containers : name => join(".", [name, var.namespace, "svc.cluster.local"])
    if container.service_port != null
  }
}

output "host_tailscale" {
  value = {
    for name, container in var.containers : name => module.dns_tailscale[name].dns_name
    if container.service_port != null
  }
}
