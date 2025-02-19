output "host_k8s" {
    value = join(".", [var.name, var.namespace, "svc.cluster.local"])
}

output "host_tailscale" {
    value = var.tailscale == null ? "" : module.dns_tailscale[0].dns_name
}
